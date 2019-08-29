
#! /bin/bash

set -eo pipefail

# Deploy only if we're testing the master branch
if [ "$TRAVIS_BRANCH" == "master" ] || [ "$TRAVIS_BRANCH" == "pantheon" ]; then
  echo "Deploying branch: $TRAVIS_BRANCH"
  bash $TRAVIS_BUILD_DIR/bin/push-to-pantheon
else
  echo "Skipping Pantheon deploy because it's not a deployable branch"
fi
