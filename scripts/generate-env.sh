#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Define the .env.local file path
ENV_FILE=$DIR/../".env.local"

# Remove existing .env.local if it exists
if [ -f "$ENV_FILE" ]; then
    rm "$ENV_FILE"
fi

# Create and write environment variables from GitLab CI/CD to .env.local
cat <<EOF > $ENV_FILE
### Symfony Local Environment Configuration ###
OPENID_PROVIDER_URL=${OPENID_PROVIDER_URL}
OPENID_CLIENT_ID=${OPENID_CLIENT_ID}
OPENID_CLIENT_SECRET=${OPENID_CLIENT_SECRET}
OPENID_REDIRECT_URL=${OPENID_REDIRECT_URL}
KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN}
KEYCLOAK_PWD=${KEYCLOAK_PWD}
KEYCLOAK_REALM=${KEYCLOAK_REALM}

EOF

# Display message
echo ".env.local file has been created with GitLab variables."
