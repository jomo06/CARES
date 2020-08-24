# CARES_Act

## Purpose

Data engineering and analysis of CARES Act funding data (this portion in Python specifically), in service of a partnership between the National Press Foundation and DataKind DC. The work done here will be used to publish articles on the efficacy and various facets of CARES Act (round 1, at least) stimulus funding.

## Prerequisites

* conda environment manager, if you don't want to use Docker
* Docker Desktop if you want to go the Docker route

## How to Use

### The Docker Approach

See main project README.



## Project Organization


    ├── LICENSE
    ├── Makefile           <- Makefile with commands like `make data` or `make train`
    ├── README.md          <- The top-level README for developers using this project.
    ├── data
    │   ├── external       <- Data from third party sources.
    │   ├── interim        <- Intermediate data that has been transformed.
    │   ├── processed      <- The final, canonical data sets for modeling.
    │   └── raw            <- The original, immutable data dump.
    │
    ├── docs               <- A default Sphinx project; see sphinx-doc.org for details
    │
    ├── docker             <- Assets needed to spin up a Docker container with the proper dependencies for running the code
    │
    ├── environment.yml    <- conda dependencies file for spinning up a virtual environment with the proper packages. Note that it can be generated via `conda env export -n CARES_Act -f environment.yml --no-builds`
    │
    ├── models             <- Trained and serialized models, model predictions, or model summaries
    │
    ├── notebooks          <- Jupyter notebooks. Naming convention is a number (for ordering),
    │                         the creator's initials, and a short `-` delimited description, e.g.
    │                         `1.0-jqp-initial-data-exploration`.
    │
    ├── references         <- Data dictionaries, manuals, and all other explanatory materials.
    │
    ├── reports            <- Generated analysis as HTML, PDF, LaTeX, etc.
    │   └── figures        <- Generated graphics and figures to be used in reporting
    │
    ├── requirements.txt   <- The requirements file for reproducing the analysis environment, e.g.
    │                         generated with `pip freeze > requirements.txt`
    │
    ├── setup.py           <- makes project pip installable (pip install -e .) so src can be imported
    ├── src                <- Source code for use in this project.
    │   ├── __init__.py    <- Makes src a Python module
    │   │
    │   ├── data           <- Scripts to download or generate data
    │   │   └── make_dataset.py
    │   │
    │   ├── features       <- Scripts to turn raw data into features for modeling
    │   │   └── build_features.py
    │   │
    │   ├── models         <- Scripts to train models and then use trained models to make
    │   │   │                 predictions
    │   │   ├── predict_model.py
    │   │   └── train_model.py
    │   │
    │   └── visualization  <- Scripts to create exploratory and results oriented visualizations
    │       └── visualize.py
    │
    └── tox.ini            <- tox file with settings for running tox; see tox.readthedocs.io


## Data

A copy of the raw data used in this project [can be found here](https://sba.app.box.com/s/tvb0v5i57oa8gc6b5dcm9cyw7y2ms6pp). This covers all datasets, for all states, above and below the $150K loan threshold for the Paycheck Protection Program.

Note that these data are [rife with errors](https://qz.com/1878225/heres-what-we-know-is-wrong-with-the-ppp-data/), which hopefully this project will be able to rectify.

--------

<p><small>Project based on the <a target="_blank" href="https://drivendata.github.io/cookiecutter-data-science/">cookiecutter data science project template</a>. #cookiecutterdatascience</small></p>
