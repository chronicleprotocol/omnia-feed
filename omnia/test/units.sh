#!/bin/bash
set -e

for f in "$(cd "${BASH_SOURCE[0]%/*}"; pwd)"/units/*.sh;
do
  echo "======================================"
  echo "Running: $f"
  echo "======================================"
  # Running unit test
  bash "$f"

  # Cehcking result
  res=$?
  if [ $res -ne 0 ]; then
    echo "--------------------------------------"
    echo "Failed to run: $f"
    echo "--------------------------------------"
    exit $res
  fi
done