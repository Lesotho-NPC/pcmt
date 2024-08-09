# S3 Restore

This docker image creates a container that are used to get a directory
to a given S3 bucket.
We mount volume file_storage from fpm to container so any changes will reflect.
## Configuration

Configuration is done by environment variable:

- CRED_PATH: The local path to a file that holds credentials, and optionally
    other configuration settings.  Normally this file is mounted into the
    container (e.g. through docker secrets).  Defaults to 
    `/run/secrets/s3-creds`.
- MYSQL_CRED_PATH: The local path to a file that holds credentials, and optionally
  other configuration settings.  Normally this file is mounted into the
  container (e.g. through docker secrets).  Defaults to
  `/run/secrets/mysql-creds`.
- AWS_ACCESS_KEY_ID: The AWS Access key id to use for the S3 bucket.
- AWS_SECRET_ACCESS_KEY: The AWS secret access key to use for the S3 bucket.
- LOCAL_DIR_TO_SYNC_IN: Full path to folder on S3 to sync from. Defaults to `/backup` if not given.
- S3_BUCKET (optional): The path and name of the S3 Bucket to use.  May include 
    a sub-path within the bucket to sync to.  e.g. `s3://BUCKET_NAME` and 
    `S3://BUCKET_NAME/SOME/SUB/PATH` are valid.
## Script
`cmd-to-run.sh` contains the bash cmd that will be executed
This will retrieve from S3 the most recent chronological database and asset backups, and restore them.
## Example

Given the file `s3-creds`:

```shell
AWS_ACCESS_KEY_ID=someaccesskeyid
AWS_SECRET_ACCESS_KEY=somesecretaccesskey
S3_BUCKET=s3://some-bucket
```

Then we could sync `s3://some-bucket/backups/` to `/file_storage/`:

```shell
docker run -v "$(pwd)/s3-creds:/run/secrets/s3-creds" \
    -v file_storage:/file_storage \
    -e LOCAL_DIR_TO_SYNC_IN="/backups/"
    -e S3_BUCKET=${PCMT_S3_BUCKET}
    pcmt/s3-retore
```

Notice that we can mix environment variables both directly in the `docker run` command with `-e` as well as place them in `s3-creds`.
