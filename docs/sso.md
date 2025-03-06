# Single Sign On (SSO)

Bundle for PCMT to use Keycloak Identity provider

## OpenID Connect w/ Keycloak

The Authorization Code flow redirects the user agent to Keycloak. Once the user has successfully authenticated with Keycloak, an Authorization Code is created and the user agent is redirected back to the application. The application then uses the authorization code along with its credentials to obtain an Access Token, Refresh Token and ID Token from Keycloak [Secure applications and services with OpenID Connect](https://www.keycloak.org/securing-apps/oidc-layers).
````plantuml
autonumber
PCMT -> KeyCloak : Authentication request

alt successful case
    KeyCloak -> PCMT: Authentication Accepted
    KeyCloak -> PCMT: Authorization Code
    PCMT -> KeyCloak: Authorization Code
    KeyCloak -> PCMT: Access Token, Refresh Token and ID Token
else failed case
    KeyCloak -> PCMT: Authentication Failure
end
````

### Background user discovery
REST API for the Keycloak Admin

[KeyCloak rest api #user](https://www.keycloak.org/docs-api/latest/rest-api/#_users)


```plantuml
participant UserDiscoverySync as userSync
database pcmtUser
participant Keycloak

userSync -> Keycloak : GET /admin/realms/{realm}/users
Keycloak -> userSync : <User Data>

loop all users
userSync -> pcmtUser : fetch users w/ identify

activate userSync
userSync -> userSync : find new user by identify
deactivate userSync

userSync -> pcmtUser : add new user
end
```

Where

- _realm_ is the name of the shared Keycloak realm
- _User Data_ that PCMT cares about is:
  - username
  - user first name
  - user last name
  - user email

Where the _email_ field will be primarily used for uniqueness.