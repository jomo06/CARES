from __future__ import print_function
import pickle
import os.path

import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

KEYS_PATH = '/home/jovyan/work/secure_keys/token.pickle'

#os.chdir(KEYS_PATH)

# If modifying these scopes, delete the file token.pickle.
# Scopes can be defined using the options here: https://developers.google.com/identity/protocols/oauth2/scopes#drive
SCOPES = [
    'https://www.googleapis.com/auth/drive.metadata.readonly', # allows listing metadata
    'https://www.googleapis.com/auth/drive.readonly', # allows downloading files
#    'https://www.googleapis.com/auth/drive.file' # allows manipulation of files, but not metadata
]

def generate_creds_using_service_account(json_path):
    '''
    If using a service account with Google Drive, generate the
    creds with the following methods. Doesn't use the pickling
    paradigm below, but DOES require you to share the data folder
    with the service account email explicitly, or else the
    service account will have access to nothing in its drive.
    '''

    SCOPE = ['https://www.googleapis.com/auth/drive']

    ## this is the JSON that was generated from the Google API
    ## Console (see https://github.com/googleapis/google-api-python-client/blob/master/docs/oauth-server.md#creating-a-service-account)
    SERVICE_ACCOUNT_FILE = 'python/auth_payload.json'

    credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPE)
    return credentials

def main(service_account=False):
    """Shows basic usage of the Drive v3 API.
    Prints the names and ids of the first 10 files the user has access to.
    """
    print(os.path.abspath(sys.argv[0]))
    creds = None
    # The file token.pickle stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    if service_account is False:
        if os.path.exists('token.pickle'):
            with open('token.pickle', 'rb') as token:
                creds = pickle.load(token)
        # If there are no (valid) credentials available, let the user log in.
        if not creds or not creds.valid:
            #if creds and creds.expired and creds.refresh_token:
            if False:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(
                    'credentials.json', SCOPES)
                creds = flow.run_local_server(port=0)
            # Save the credentials for the next run
            with open('token.pickle', 'wb') as token:
                pickle.dump(creds, token)
    else:
        creds = generate_creds_using_service_account(google_drive_token_path)

    service = build('drive', 'v3', credentials=creds)

    # Call the Drive v3 API
    results = service.files().list(
        pageSize=10, fields="nextPageToken, files(id, name)").execute()
    items = results.get('files', [])

    if not items:
        print('No files found.')
    else:
        print('Files:')
        for item in items:
            print(u'{0} ({1})'.format(item['name'], item['id']))

if __name__ == '__main__':
    main()
