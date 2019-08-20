
#! /bin/bash
# Deploy only if it's not a pull request
if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  # Deploy only if we're testing the master branch
  if [ "$TRAVIS_BRANCH" == "pantheon" ]; then
    # Setup password-less passphrase for Pantheon
    openssl aes-256-cbc -K $encrypted_8a30a4e5a3eb_key -iv $encrypted_8a30a4e5a3eb_iv -in $TRAVIS_BUILD_DIR/pantheon-hash.txt.enc -out $TRAVIS_BUILD_DIR/pantheon-hash.txt -d
    cp travis-ci-key ~/.ssh/id_rsa
    chmod 0600 ~/.ssh/id_rsa
    echo "Deploying $TRAVIS_BRANCH"
    bash $TRAVIS_BUILD_DIR/bin/push-to-pantheon
  else
    echo "Skipping Pantheon deploy because it's not a deployable branch"
  fi
else
  echo "Skipping Pantheon deploy because it's a PR"
fi