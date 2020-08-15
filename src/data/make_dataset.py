# -*- coding: utf-8 -*-
import click
import logging
from pathlib import Path
from dotenv import find_dotenv, load_dotenv

import pandas as pd
import numpy as np

import datetime as dt
import pytz

from io import BytesIO

import pickle
from googleapiclient.discovery import build

from tqdm import tqdm
# Make sure any previous runs of tqdm that were interrupted are cleared out
getattr(tqdm, '_instances', {}).clear()

import argparse

log_fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
logging.basicConfig(level=logging.INFO, format=log_fmt)

logger = logging.getLogger()


def pull_ppp_data(google_drive_token_path='/home/jovyan/work/secure_keys/token.pickle', local_copy=None):
    '''
    Pulls down files from the DataKind NPF Google Drive
    then merges SBA PPP CSV files found into a single
    pandas DataFrame for further analysis.

    Fair warning: initial testing indicates that this will take
    a little more than 8 minutes to complete. So save it locally to 
    avoid downloading and stitching steps if you can.


    Parameters
    ----------
    google_drive_token_path: str. Filepath to local copy of token.pkl file
        that represents pre-authorized access of file read-only (at least)
        scope to the Google Drive of interest.

        If you don't have this, go to the Python Quickstart tutorial
        at https://developers.google.com/drive/api/v3/quickstart/python
        to find instructions on how to create the token file so this
        code can be run successfully. Note that this token generation
        process doesn't work from within the Docker instance unfortunately,
        so you'll need to do it in your local instance of python 3.6+ with
        the necessary packages installed (perhaps in a conda environment).

        Make sure you don't upload your token to GitHub!

    local_copy: str. If not None, interpreted as the filepath to use
        for saving a local copy of the merged CSV file to avoid
        re-downloading it later.


    Returns
    -------
    pandas DataFrame with all of the raw PPP data loaded.
    '''

    # Pull in our Google Drive creds
    with open(google_drive_token_path, 'rb') as token:
        creds = pickle.load(token)
        
    service = build('drive', 'v3', credentials=creds)

    # Find the info for All Data by State folder that contains raw PPP data
    data_folder_info = service.files().list(q = "name = 'All Data by State'")\
    .execute().get('files', [])[0]

    query = f"'{data_folder_info['id']}' in parents \
and mimeType = 'application/vnd.google-apps.folder'"
    
    data_subfolders = service.files().list(q = query).execute()\
    .get('files', [])

    # Find all CSV files in the child folders
    data_subfolder_ids = []

    # Get the subfolder IDs
    for subfolder in data_subfolders:
        data_subfolder_ids.append(subfolder['id'])

    query = " in parents or ".join([f"'{folder_id}'" \
        for folder_id in data_subfolder_ids])
    query += " in parents"

    # Guarantee OR statements are evaluated together first, then AND
    query = f"({query})"
    query +=  "and mimeType = 'text/csv'"

    # Get all CSV file IDs from data subfolders as a list of ByteStrings
    data_file_ids = service.files().list(q = query).execute().get('files', []) 

    # Pull and concatenate all ByteStrings, skipping headers, 
    # and decode into single DataFrame for further analysis
    # Note that this would be more efficient long-term to ZIP all CSVs into one file 
    # and then pull that down alone
    for i, file in enumerate(tqdm(data_file_ids)):
        if i == 0:
            data_str = service.files()\
            .get_media(fileId=file['id'])\
            .execute()
            
        # just concatenating here, without header, since we already have it
        else:
            temp_data_str = service.files()\
            .get_media(fileId=file['id'])\
            .execute()
            
            # Assuming here that header is the same across files and thus we can skip it
            # Find end of header by finding first newline character
            data_start_index = temp_data_str.find(b"\n") + 1

            data_str += temp_data_str[data_start_index:]
            # Check that \r\n is at end of string, add it if not
            if data_str[-2:] != b'\r\n':
                data_str += b'\r\n'

    # Decode ByteString into something that pandas can make a DataFrame out of
    data = data_str.decode('utf8').encode('latin-1')

    # Likely will return error/warning due to mixed dtypes and suggest 
    # making low_memory=False, but that will cause OOM errors 
    # that shutdown python kernel...
    df = pd.read_csv(BytesIO(data), encoding='latin-1', low_memory=True)

    if local_copy is not None:
        df.to_csv(local_copy, index=False)


    return df


def transpose_columns(
    df, 
    rows_affected=None,
    columns_to_freeze=None, 
    columns_to_move=None, 
    transposition_distance=0
    ):
    '''
    Moves whole columns from one position to another, as a group.
    Useful when you find that there's a pattern wherein a bunch of columns 
    were off by 1/2/3/etc. from the column they were supposed to be in.


    Parameters
    ----------
    df: pandas DataFrame with the improperly transposed columns data.

    rows_affected: pandas Index object. Indicates the rows in ``df`` that
        should be shifted, with the rest being left alone.

    columns_to_freeze: list of str containing the names of the columns that
        shouldn't be transposed. All other columns not in this list will be 
        moved. If this is None, ``columns_to_move`` should not be None.

    columns_to_move: list of str containing the names of the columns that
        should be transposed. All other columns will be left alone. If this is 
        None, ``columns_to_freeze`` should not be None.

    transposition_distance: int. Indicates how many columns to the right
        (if positive) or left (if negative) to move the columns.
    '''

    output = df.copy()

    if columns_to_freeze and columns_to_move:
        raise ValueError("columns_to_freeze and columns_to_move are both set, \
please only set one.")

    elif columns_to_freeze:
        output.loc[rows_affected, 
        output.columns.drop(columns_to_freeze)] = \
        output.loc[rows_affected, 
        output.columns.drop(columns_to_freeze)]\
        .shift(periods=transposition_distance, axis='columns')

    elif columns_to_move:
        output.loc[rows_affected, 
        columns_to_move] = \
        output.loc[rows_affected, 
        columns_to_move]\
        .shift(periods=transposition_distance, axis='columns')

    else:
        logger.warn("No values set for columns_to_freeze or columns_to_move, \
so no transposition performed.")
        
    return output


def clean_ppp_data(df):
    '''
    Tackles various SBA PPP data cleaning tasks as a one-liner.


    Parameters
    ----------
    df: pandas DataFrame. Raw input data that needs cleaning.


    Returns
    -------
    pandas DataFrame with all input columns cleaned up and possibly with
    extra columns as needed as a result of the cleaning process.
    '''

    # Find rows where State column is numeric or is a string with numeric chars
    tqdm.pandas(desc="Finding the rows in which numeric values exist for the \
State column...")
    numeric_states_index = df[(df['State'].progress_apply(np.isreal)) | \
    (df['State'].str.isnumeric())].index

    logger.info(f"{(len(numeric_states_index) / len(df)) * 100}% of the \
loans have a numeric State value")

    # Transpose columns by 2 to the right when State is numeric
    output = transpose_columns(
        df,
        rows_affected=numeric_states_index,
        columns_to_freeze='LoanRange', 
        transposition_distance=2
        )

    logger.info("Note that 'AE' is an abbreviation for the 'state' of \
Armed Forces - Europe. It's valid.")

    # FI entry is actually supposed to be FL, according to ZIP
    output.loc[output['State'] == 'FI', 'State'] = 'FL'



    return output




#@click.command()
#@click.argument('input_filepath', type=click.Path(exists=True))
#@click.argument('output_filepath', type=click.Path())
def main(input_filepath, output_filepath):
    """ Runs data processing scripts to turn raw data from (../raw) into
        cleaned data ready to be analyzed (saved in ../processed).
    """
    pull_ppp_data(input_filepath, local_copy=output_filepath)






if __name__ == '__main__':

    # not used in this stub but often useful for finding various files
    project_dir = Path(__file__).resolve().parents[2]

    # find .env automagically by walking up directories until it's found, then
    # load up the .env entries as environment variables
    load_dotenv(find_dotenv())

    ########### SETUP COMMAND-LINE ARUGMENTS ###########

    parser = argparse.ArgumentParser(description='Runs the data ingest \
pipeline.')

    parser.add_argument('-g', '--google_drive_token_path', type=str,
        default="/home/jovyan/work/secure_keys/token.pickle",
                        help='Filepath of the token.pkl file containing \
user credentials for Google Drive where raw data are stored.')

    parser.add_argument('-l', '--local_copy', type=str,
        default=None,
                        help='Optional filepath for where resultant \
merged data will be stored. Make sure it is a named *.csv file.')

    args = vars(parser.parse_args())

    

    main(args['google_drive_token_path'], args['local_copy'])
