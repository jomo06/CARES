## Quick how-to on grabbing creds with python
## to pass into drive functions to pull recent data
## used in some of the notebooks

from google.oauth2 import service_account

SCOPE = ['https://www.googleapis.com/auth/drive']

## this is the JSON that was generated from
## the Google API Console (see https://github.com/googleapis/google-api-python-client/blob/master/docs/oauth-server.md#creating-a-service-account)
SERVICE_ACCOUNT_FILE = 'python/auth_payload.json'

credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPE)
