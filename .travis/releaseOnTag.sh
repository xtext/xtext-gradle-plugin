#!/bin/bash
set -ev
if [ -n "${TRAVIS_TAG}" ]; then
  ./gradlew release "-PreleaseVersion=${TRAVIS_TAG}"
fi
