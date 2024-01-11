#!/bin/bash

set -euo pipefail

if which actionlint > /dev/null
then
  actionlint "$@"
else
  true
fi
