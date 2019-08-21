
#! /bin/bash
# Deploy only if it's not a pull request
if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  # Deploy only if we're testing the master branch
  if [ "$TRAVIS_BRANCH" == "pantheon" ]; then
    echo "Deploying $TRAVIS_BRANCH"
    bash $TRAVIS_BUILD_DIR/bin/push-to-pantheon
  else
    echo "Skipping Pantheon deploy because it's not a deployable branch"
  fi
else
  echo "Skipping Pantheon deploy because it's a PR"
fi