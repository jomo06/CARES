# CARES_Act

## Purpose

Data engineering and analysis of CARES Act funding data (this portion in Python specifically), in service of a partnership between the National Press Foundation and DataKind DC. The work done here will be used to publish articles on the efficacy and various facets of CARES Act (round 1, at least) stimulus funding.

## Prerequisites

* conda environment manager, if you don't want to use Docker
* Docker Desktop if you want to go the Docker route

## How to Use

### The Docker Approach

1. From the terminal, in the project's root directory, enter `docker-compose -f docker/docker-compose.yml up --build` and the container should successfully spin up, with log messages in the terminal indicating this.
    * If this isn't your first time using the service (e.g. you've already built the image once) and you don't have any updates to the `environment.yml` file that change the container's dependencies, then just use `docker-compose -f docker/docker-compose.yml up`.
    * **Note:** if you have updated the environment.yml file, you'll need to use the Dockerfile as part of the install (instead of pulling an image from DockerHub) so that it can re-build the image using the new requirements. You should probably also update the tag on line 5 of `docker/docker-compose.yml` to reflect the new requirements of the image so it doesn't overwrite your old, functioning image.
        * Additionally, the most effective way to update the environment for future builds is to update the `environment.yml` file by running `conda env export -f environment.yml` from within a terminal tab of JupyterLab in a running container that has the new requirements installed. Note the lack of `--no-builds` at the end: this can cause undue delay during image building by making the conda solver figure out the exact hashes to use for your package versions. Since we're simply updating the image based upon a modified container originally spun up using that same image, there's no need to exclude the exact builds from the conda export process. 

2. Go to [http://localhost:10000/lab](http://localhost:10000/?token=<token>) for access.
    * Note that JupyterLab will require you to enter a token before it will allow you access via the browser. This token can be found in the log messages printed to your terminal after starting the service via `docker-compose` (look for the line that says "Or copy and paste one of these URLs:" and then copy the portion of the URL that comes after "?token=").

WARNING: before doing any of this, make sure your Docker Desktop has been given access to a sizeable fraction of your system memory (e.g. the machine all of this was developed on gave it 8 GB). This will ensure it doesn't run out of memory while doing the initial data ingest.

#### Notes

1. If you want to use the terminal for any activities (e.g. adding new packages to the environment), make sure you first activate the environment via `conda activate <environment_name>`
    * Whenever you install new packages, if you want them to be available the next time you spin this environment up, please make sure you first overwrite the `environment.yml` file with your new dependencies via (assuming your terminal is currently in the `notebooks/` directory) `conda env export -f ../environment.yml --no-builds`
2. The working directory in which you launch your container via `docker-compose.yml` will be mounted inside the Docker container, meaning that you'll see any notebooks, scripts, etc. that you already had in that directory when you spun up the container.
3. Check the kernel you're using for any new notebooks to ensure that it's set to the proper conda environment.
4. In order to utilize plotly visualization within notebooks in JupyterLab, you need to agree to do the re-build that you are prompted to do when first opening up Jupyterlab in the container. After agreeing, wait a minute or two until it prompts you to reload JupyterLab. Once you do so, plotly functionality should be enabled for that container.

### The conda Approach

1. From the terminal, run `conda env create -f environment.yml`


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
