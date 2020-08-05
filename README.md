# CARES

CARES Act data: PPP, EIDL and more.

Data files can be downloaded from the [DataKind Google Drive](https://drive.google.com/drive/folders/1oGw8sobXw4PC_SNQ9AcfCuR8RBu-te2o?usp=sharing)

## Directory Structure

- `bin/` for in production executable files (like reading in the PPP data)
- `CARES/` folder with individual project subfolders on the CARES act data. 
This is so if we eventually want to make a package, it's set up for one. 
Enhancements people make can go here, grouped by "project". A project is any 
discreet enhancement to the data, like adding in NAICS code industry 
identifiers. All projects should be documented in the README. 
Project examples:
  - `CARES/NAICS/` is where scripts go for joining NAICS and PPP data
  - `CARES/census_mapping/` for US census joins, mapping, etc.
- `docs/` for references, data dictionaries, manuals, etc. Each project should 
have an accompanying `docs/project_name/` folder
- `data/` for raw data files that scripts rely on or that others would find 
useful--I think tidied data files should be uploaded to Google Drive to make
it easier for others to use. Please organize data files roughly by topic! 
Please cite sources in the README!
- `tests/` for each project's unit tests; i.e., `tests/NAICS/`

All finalized code should be able to be run on the output of the setup scripts
in `bin/`, or on a dataset read in as a CSV file created by cleaning code.

## Data Sources

- PPP Loan Data: [Small Business Administration's DropBox](https://sba.app.box.com/s/tvb0v5i57oa8gc6b5dcm9cyw7y2ms6pp)
- NAICS code dictionary [US Census NAICS Files](https://www.census.gov/eos/www/naics/downloadables/downloadables.html)

## PPP Data Dictionary

### Structure

Rows: 4,885,388

Potential duplicate rows: ~4,353 (still investigating)

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

#### Notes

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


`City` is not a formalized field and contains open-text values, meaning it 
cannot be used as-is for any kind of geo-coding or validation


`State` contains a small number of odd values: 

|State |    n |  % |                                                             notes |
|:-----|-----:|---:|------------------------------------------------------------------:|
|AE    |     1| 0.0| zipcode suggests this is indeed a military address outside the US |
|FI    |     1| 0.0| zipcode suggests this should be FL                                |
|XX    |   210| 0.0|                                                                   |


`Zip`: all non-missing values are in valid 5 digit format, but not all 
of those match to real zip codes. Further validation pending. Note also 
that just because a zip code is valid does not mean it can be mapped to 
a ZCAT (e.g., PO Box Zips)


For `RaceEthnicity`, `Gender`, and `Veteran`, most of the data are 
"Not Answered" due to these questions being optional.


`NonProfit` has only Y or NA values, and so can be assumed to be a required
question, implying actual Missingness of 0%


`JobsRetained` contains some improbable values, and many values are Zero:

|JobsRetained    |     n |   % |
|:---------------|------:|----:|
|Less than Zero  |      7|  0.0|
|Zero            | 554146| 11.3|
