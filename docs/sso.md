# Single Sign On (SSO)

TODO:  Overview of goal, tech and flows

## OpenID Connect w/ Keycloak

TODO: overview of the flow used, how Keycloak is part of it, and configuration

### Background user discovery

WIP:  still vetting this as a concept

[Keycloak User Api](https://www.keycloak.org/docs-api/latest/rest-api/#_users)

```plantuml
participant UserDiscoverySync as userSync
database pcmtUser
participant Keycloak

userSync -> Keycloak : GET /admin/realms/{realm}/users
Keycloak -> userSync : <User Data>

loop all keycloak users
userSync -> pcmtUser : fetch users w/ email

activate userSync
userSync -> userSync : find new user by email

userSync -> pcmtUser : add new pcmt user
deactivate userSync

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