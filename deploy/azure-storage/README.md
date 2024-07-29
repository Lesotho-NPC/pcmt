# Azure Sync

This docker image creates container's that are used to sync a directory
to a given S3 bucket on a schedule as defined by cron.

This images extends the Cron image, and therefore it's configuration options.

## Configuration

Configuration is done by environment variable:

- CRED_PATH: The local path to a file that holds credentials, and optionally