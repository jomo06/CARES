# CARES

CARES Act data: PPP, EIDL and more.

Data files can be downloaded from the [DataKind Google Drive](https://drive.google.com/drive/folders/1oGw8sobXw4PC_SNQ9AcfCuR8RBu-te2o?usp=sharing)

## TOC

1. [Contributing.](#cont)
2. [Directory Structure.](#dir)
3. [Using Docker](#docker)
3. [Data Sources.](#data)
4. [PPP Data Dictionary](#ppp)
5. [Enhancements](#enh)

---

<a name="cont"/>

## Contributing

Please either [fork](https://docs.github.com/en/enterprise/2.20/user/github/getting-started-with-github/fork-a-repo) or [make a development branch](https://thenewstack.io/dont-mess-with-the-master-working-with-branches-in-git-and-github/) of the repo to contribute.

Please ask a fellow volunteer to review your code with a [pull request](https://yangsu.github.io/pull-request-tutorial/) before merging with the master branch! You can always ask [@JohnMcCambridge](https://github.com/JohnMcCambridge)
or [@kbmorales](https://github.com/kbmorales) if you don't know who to ask to
review!

<a name="dir"/>

## Directory Structure

- `bin/` for in production executable files
  - `bin/pull_data.R` authenticates with Google Drive, downloads PPP flat files
  - `bin/ppp_data_merge.R` reads in PPP flat files
- `code/` folder with individual project subfolders on the CARES act data.
Enhancements people make can go here, grouped by "project". A project is any
discreet enhancement to the data, like adding in NAICS code industry
identifiers. All projects should be documented in the README.
Project examples:
  - `code/NAICS/` is where scripts go for joining NAICS and PPP data
  - `code/census_mapping/` for US census joins, mapping, etc.
- `docs/` for references, data dictionaries, manuals, etc. Each project should
have an accompanying `docs/project_name/` folder
- `data/` for raw data files that scripts rely on or that others would find
useful--I think tidied data files should be uploaded to Google Drive to make
it easier for others to use. Please organize data files roughly by topic!
Please cite sources in the README!
- `tests/` for each project's unit tests; i.e., `tests/NAICS/`
- `src/` contains python code that can be used together as a single `src` package and installed in a dev environment via `pip install -e .` when in the repo root.
- `docker/` contains the elements needed to run a Docker instance of the python code, to ensure consistent dependency trees across data scientists
- `python/` contains some extra elements for python data exploration, such as interactive notebooks that can be used to test out basic concepts prior to committing them as scripts/modules.

All finalized code should be able to be run on the output of the setup scripts
in `bin/` or `src/`, or on a dataset read in as a CSV file created by cleaning code.

<a name="docker"/>

## Using Docker

If you want to work from a consistent dependency tree, the best way is through Docker containerization. Note that, for now, this is specific only to python users, but R users could incorporate necessary elements in the Dockerfile if desired to make it work more broadly.

1. From the terminal, in the project's root directory, enter `docker-compose -f docker/docker-compose.yml up --build` and the container should successfully spin up, with log messages in the terminal indicating this.
    * If this isn't your first time using the service (e.g. you've already built the image once) and you don't have any updates to the `environment.yml` file that change the container's dependencies, then just use `docker-compose -f docker/docker-compose.yml up`.
    * **Note:** if you have updated the environment.yml file, you'll need to use the Dockerfile as part of the install (instead of pulling an image from DockerHub) so that it can re-build the image using the new requirements. You should probably also update the tag on line 5 of `docker/docker-compose.yml` to reflect the new requirements of the image so it doesn't overwrite your old, functioning image.
        * Additionally, the most effective way to update the environment for future builds is to update the `environment.yml` file by running `conda env export -f environment.yml` from within a terminal tab of JupyterLab in a running container that has the new requirements installed. Note the lack of `--no-builds` at the end: this can cause undue delay during image building by making the conda solver figure out the exact hashes to use for your package versions. Since we're simply updating the image based upon a modified container originally spun up using that same image, there's no need to exclude the exact builds from the conda export process.

2. Go to [http://localhost:10000/lab](http://localhost:10000/?token=<token>) for access.
    * Note that JupyterLab will require you to enter a token before it will allow you access via the browser. This token can be found in the log messages printed to your terminal after starting the service via `docker-compose` (look for the line that says "Or copy and paste one of these URLs:" and then copy the portion of the URL that comes after "?token=").
    * JupyterLab may direct you to use port 8888 or the like -- go with port 1000 above, regardless of what the "copy-paste" links in the terminal says.

WARNING: before doing any of this, make sure your Docker Desktop has been given access to a sizeable fraction of your system memory (e.g. the machine all of this was developed on gave it 8 GB). This will ensure it doesn't run out of memory while doing the initial data ingest.


### Notes

1. If you want to use the terminal for any activities (e.g. adding new packages to the environment), make sure you first activate the environment via `conda activate <environment_name>`
    * Whenever you install new packages, if you want them to be available the next time you spin this environment up, please make sure you first overwrite the `environment.yml` file with your new dependencies via (assuming your terminal is currently in the `notebooks/` directory) `conda env export -f ../environment.yml --no-builds`
2. The working directory in which you launch your container via `docker-compose.yml` will be mounted inside the Docker container, meaning that you'll see any notebooks, scripts, etc. that you already had in that directory when you spun up the container.
3. Check the kernel you're using for any new notebooks to ensure that it's set to the proper conda environment.
4. In order to utilize plotly visualization within notebooks in JupyterLab, you need to agree to do the re-build that you are prompted to do when first opening up Jupyterlab in the container. After agreeing, wait a minute or two until it prompts you to reload JupyterLab. Once you do so, plotly functionality should be enabled for that container.



## Data Sources

- PPP Loan Data: [Small Business Administration's DropBox](https://sba.app.box.com/s/tvb0v5i57oa8gc6b5dcm9cyw7y2ms6pp)
- NAICS code dictionary [US Census NAICS Files](https://www.census.gov/eos/www/naics/downloadables/downloadables.html)
- [Data catlog of other sources](https://docs.google.com/spreadsheets/d/1d3wVJTFg3zjTVyjzy8hADxxTp1q5rDVbRKDJ6WyyNZk/edit#gid=0) assembled by Dave RM

<a name="ppp"/>

## PPP Data Dictionary

### Structure

Rows: 4,885,388 (0630 dataset); 5,212,128 (0808 dataset) 

Potential duplicate rows: ~4,353 (still investigating - first dataset)

Variables:

|variable      | n Missing |   % Missing |                        Validation Notes |
|:-------------|----------:|------------:|----------------------------------------:|
|LoanRange     |    4224170|         86.5| see notes                               |
|BusinessName  |    4224171|         86.5| no values for loan amounts under 150K   |
|Address       |    4224170|         86.5| no values for loan amounts under 150K   |
|City          |          1|          0.0| see notes                               |
|State         |          0|          0.0| see notes                               |
|Zip           |        224|          0.0| see notes                               |
|NAICSCode     |     133527|          2.7| validation pending                      |
|BusinessType  |       4723|          0.1|                                         |
|RaceEthnicity |          0|          0.0| 89.3% "Unanswered"                      |
|Gender        |          0|          0.0| 77.7% "Unanswered"                      |
|Veteran       |          0|          0.0| 84.7% "Unanswered"                      |
|NonProfit     |    4703708|         96.3| see notes                               |
|JobsRetained  |     324122|          6.6| see notes                               |
|DateApproved  |          0|          0.0| earliest: 2020-04-03 latest: 2020-06-30 |
|Lender        |          0|          0.0|                                         |
|CD            |          0|          0.0|                                         |
|LoanAmount    |     661218|         13.5| no values for loan amounts over 150K    |


# preliminary notes from 0808 dataset

`total rows`: 5,212,128

`LoanRange`: 4,549,613 NA values

`BusinessName`: 4,549,613 NA values

Also present are some invalid or strange unique business names:
- 1970
- 1990
- 1999
- 3945
- 95112
- 995782.5
- 200222222
- 462048120
- 2815496822
- 8187853713
- 8436795355
- 9148415738
- 80028795173
- #NAME? [2 loans]
- 4/1/2002
- 9/1/2014
- NEW APPLICATION [51 loans]
- N/A [5 loans]
- NOT AVAILABLE [5 loans]

and here are business names that appear MANY times:
- FIRST UNITED METHODIST CHURCH							[35 loans]
- FIRST BAPTIST CHURCH									[24 loans]
- THE ROMAN CATHOLIC WELFARE CORPORATION OF OAKLAND		[23 loans]
- THE CATHOLIC BISHOP OF CHICAGO						[19 loans]
- TRINITY LUTHERAN CHURCH								[19 loans]
- IMMACULATE CONCEPTION CHURCH							[13 loans]
- CALVARY BAPTIST CHURCH								[11 loans]
- CHRIST UNITED METHODIST CHURCH						[11 loans]
- SACRED HEART SCHOOL									[11 loans]
- FIRST PRESBYTERIAN CHURCH								[10 loans]


Additionally, five entries with business name of "-"

`Address`: 4,549,613 NA values

`City`: 201 entries with value of "N/A" in states as follows:

|:---|----|----|----|----|----|----|----|----|----|----|----|---:|
| AZ | CA | CO | FL | IL | LA | NH | NV | NY | OH | TX | WA | WY |
|  2 | 18 |  1 |  3 |  7 |  1 |  1 |  3 |  6 |  1 | 15 |  4 |  1 |
 
`State`: 59 unique values. FI remains uncorrected, 165 NAs

`Zip`: 36675 unique values. 196 NAs. 

`NAICSCode`: 133,144 NAs. 86,358 have value of 999990 ("Unclassifiable")

`BusinessType`: 4,570 NAs

`RaceEthnicity`: 4,675,327 

`Gender` 4,096,373            

`Veteran`: 4,450,315       

`NonProfit:` 5,029,544 NAs (only other value is Y)

`JobsRetained`: no longer exists as a variable, likely due to embarrasement at inaccuracy. Replacement variable is called "JobsReported": 337,878  NAs, 

`DateApproved`: 04/03/2020 to 08/08/2020

`Lender`: 0 NAs

`CD`: 1,017 NAs, some definite strangess around CDs not matching to State

`LoanAmount`: 662,515 NAs


|LoanRangeUnified      |      Freq|
|:---------------------|---------:|
|a $5-10 million       |     4,734|
|b $2-5 million        |    24,248|
|c $1-2 million        |    53,218|
|d $350,000-1 million  |   199,679|
|e $150,000-350,000    |   380,636|
|f $125,000 - $150,000 |   119,128|
|g $100,000 - $125,000 |   172,590|
|h  $75,000 - $100,000 |   260,379|
|i  $50,000 -  $75,000 |   423,406|
|j  $25,000 -  $50,000 |   830,119|
|k   $1,000 -  $25,000 | 2,712,932|
|l     $100 -    $1000 |    30,558|
|m      $10 -     $100 |       465|
|n           Up to $10 |        36|


|JobsReported_Grouped |      Freq|
|:--------------------|---------:|
|a 400 - 500          |     7,103|
|b 300 - 400          |     5,715|
|c 200 - 300          |    13,653|
|d 100 - 200          |    46,436|
|e  50 - 100          |   103,145|
|f  25 -  50          |   229,515|
|g  10 -  25          |   588,103|
|h   5 -  10          |   685,136|
|i   2 -   5          | 1,348,223|
|j         1          | 1,248,997|
|k      Zero          |   598,223|
|l  Negative          |         1|


|State|    Freq|
|:----|-------:|
|AE   |       1|
|AK   |  12,085|
|AL   |  70,328|
|AR   |  43,675|
|AS   |     296|
|AZ   |  85,767|
|CA   | 623,345|
|CO   | 109,171|
|CT   |  64,627|
|DC   |  13,512|
|DE   |  13,205|
|FI   |       1|
|FL   | 432,883|
|GA   | 174,425|
|GU   |   2,208|
|HI   |  25,096|
|IA   |  61,415|
|ID   |  31,055|
|IL   | 225,433|
|IN   |  83,241|
|KS   |  53,757|
|KY   |  50,671|
|LA   |  78,868|
|MA   | 118,390|
|MD   |  87,009|
|ME   |  28,309|
|MI   | 128,161|
|MN   | 102,349|
|MO   |  95,595|
|MP   |     482|
|MS   |  48,542|
|MT   |  23,907|
|NC   | 129,285|
|ND   |  20,510|
|NE   |  44,072|
|NH   |  24,742|
|NJ   | 157,402|
|NM   |  23,037|
|NV   |  45,770|
|NY   | 348,867|
|OH   | 149,152|
|OK   |  66,211|
|OR   |  66,350|
|PA   | 173,543|
|PR   |  39,543|
|RI   |  17,943|
|SC   |  67,166|
|SD   |  23,493|
|TN   |  99,574|
|TX   | 417,266|
|UT   |  52,274|
|VA   | 114,572|
|VI   |   2,057|
|VT   |  12,401|
|WA   | 107,662|
|WI   |  89,613|
|WV   |  18,065|
|WY   |  13,584|


#### these notes below apply to the 0630 dataset specifically

#### LoanRange

`LoanRange` is missing from all state data, giving the 86.5% missing
number, but actual loan amount is included instead. To address this we
have created a computed field `LoanRange_Unified` which assigns all precise
numeric loan values from the 'Under 150K' State files into compatible groups.
Within these groups, some values are improbably low e.g.:

|LoanRange       |    n |  % |
|:---------------|-----:|---:|
|Less than Zero  |     1| 0.0|
|Zero            |    71| 0.0|
|Up to $10       |   217| 0.0|
|$100 - $1000    | 26318| 0.5|

Additionally we have created numeric fields for other calcuations, such
as ranking and summing across groups: `LoanRangeMin`, `LoanRangeMid`,
`LoanRangeMax`.

#### City

`City` is not a formalized field and contains open-text values, meaning it
cannot be used as-is for any kind of geo-coding or validation

#### State

`State` contains a small number of odd values:

|State |    n |  % |                                                             notes |
|:-----|-----:|---:|------------------------------------------------------------------:|
|AE    |     1| 0.0| zipcode suggests this is indeed a military address outside the US |
|FI    |     1| 0.0| zipcode suggests this should be FL                                |
|XX    |   210| 0.0|                                                                   |


#### Zip

All non-missing values are in valid 5 digit format, but not all
of those match to real zip codes. Further validation pending. Note also
that just because a zip code is valid does not mean it can be mapped to
a ZCAT (e.g., PO Box Zips)

#### NonProfit

Has only Y or NA values, and so can be assumed to be a required question,
implying actual Missingness of 0%

#### JobsRetained

contains some improbable values, and many values are Zero:

|JobsRetained    |     n |   % |
|:---------------|------:|----:|
|Less than Zero  |      7|  0.0|
|Zero            | 554146| 11.3|

#### RaceEthnicity, Gender, and Veteran

Most of the data are "Not Answered" due to these questions being optional.

<a name="enh"/>

## Enhancements

### NAICS Codes

Adds NAICS industry identifiers to the PPP data. See the [notebook](docs/naics/naics.ipynb)
