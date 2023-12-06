# Scalyr

This image is used to create containers to monitor PCMT using [Scalyr][scalyr].

[scalyr]: https://scalyr.com

## Requirements:

- Docker daemon must be using the `json-file` logging driver.
- Scalyr account and API key with write access for logs.

## Configuration

Configuration is based on Scalyr's [docker-json].

Configuration is done by environment variable:

- `PCMT_SCALYR_CREDS_CONF`:  The path to a file which will have a Scalyr
  [snippet] with the Scalyr API Key.  Default: `/run/secrets/scalyr-creds`
- `PCMT_HOSTNAME`: The hostname of this instance of PCMT.

[docker-json]: https://app.scalyr.com/help/install-agent-docker?teamToken=pkXh_nPAxsdVbnjeRuIXEQ--#dockerJSON
[snippet]: https://app.scalyr.com/help/scalyr-agent#modularConfig

## Example

Run locally:

```shell
docker run -e PCMT_HOSTNAME=localpcmt \
    -v "$(pwd)/conf/scalyr-creds.json:/run/secrets/scalyr-creds" \
    -v "/var/run/docker.sock:/var/scalyr/docker.sock" \
    -v "/var/lib/docker/containers:/var/lib/docker/containers" \
    pcmt/scalyr
```