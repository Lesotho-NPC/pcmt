# Azure Restore

This docker image creates a container that are used to get a directory
to a given Azure blob container.
We mount volume file_storage from fpm to container so any changes will reflect.
## Configuration

Configuration is done by environment variable:

- CRED_PATH: The local path to a file that holds credentials, and optionally
    other configuration settings.  Normally this file is mounted into the
    container (e.g. through docker secrets).  Defaults to 
    `/run/secrets/azure-creds`.
- MYSQL_CRED_PATH: The local path to a file that holds credentials, and optionally
  other configuration settings.  Normally this file is mounted into the
  container (e.g. through docker secrets).  Defaults to
  `/run/secrets/mysql-creds`.
- AZURE_STORAGE_ACCOUNT: The Azure storage account.
- AZURE_STORAGE_CONTAINER_NAME: The Azure blob container.
## Script
`cmd-to-run.sh` contains the bash cmd that will be executed
This will retrieve from blob the most recent chronological database and asset backups, and restore them.
## Example

Given the file `azure-creds`:

```shell
AZURE_STORAGE_ACCOUNT=someaccount
AZURE_STORAGE_CONTAINER_NAME=somecontainer
```

Then we could sync to `/file_storage/`:

```shell
docker run -v "$(pwd)/azure-creds:/run/secrets/azure-creds" \
    -v file_storage:/file_storage \
    -e LOCAL_DIR_TO_SYNC_IN="/backups/"
    pcmt/azure-retore
```

Notice that we can mix environment variables both directly in the `docker run` command with `-e` as well as place them in `azure-creds`.
