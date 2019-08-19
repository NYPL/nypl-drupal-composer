#! /bin/bash
# Deploy only if it's not a pull request
if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  # Deploy only if we're testing the master branch
  if [ "$TRAVIS_BRANCH" == "qa" ] || [ "$TRAVIS_BRANCH" == "development" ]; then

    case "$TRAVIS_BRANCH" in
      development)
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_DEVELOPMENT
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_DEVELOPMENT
        CLUSTER_NAME=drupal-phpnginx
        WEB_APP_SERVICE_NAME="drupal-webapp"
        ;;
      qa)
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_DEVELOPMENT
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_DEVELOPMENT
        CLUSTER_NAME=drupal-phpnginx
        WEB_APP_SERVICE_NAME="drupal-webapp"
        ;;
    esac

    echo "Deploying $TRAVIS_BRANCH"
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION aws ecs update-service --cluster $CLUSTER_NAME --region us-east-1 --service $WEB_APP_SERVICE_NAME --force-new-deployment
  else
    echo "Skipping deploy because it's not a deployable branch"
  fi
else
  echo "Skipping deploy because it's a PR"
fi