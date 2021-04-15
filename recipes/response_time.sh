#!/usr/bin/env bash

curl -s -o /dev/null -w '%{time_starttransfer}\n' "$@"