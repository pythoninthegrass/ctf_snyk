#!/usr/bin/env bash

cat << 'DESCRIPTION' >/dev/null
https://learn.snyk.io/lessons/prototype-pollution/javascript/
DESCRIPTION

# post w/curl
curl -H "Content-Type: application/json" -X POST -d '{"role": "admin"}' https://api.startup.io/users/1337 && curl -X GET https://api.startup.io/users/1337/role
