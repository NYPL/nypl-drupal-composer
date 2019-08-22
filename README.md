# Composer-based Drupal Container

[![Build Status](https://travis-ci.com/NYPL/nypl-drupal-composer.svg?branch=master)](https://travis-ci.com/NYPL/nypl-drupal-composer)

Build scripts for creating environments for local development, development on NYPL's AWS
infrastructure, and, optionally, on Pantheon's platform. Uses Docker containers for local
and NYPL builds. Makes use of the container image for php/nginx built by [WebDevOps](https://hub.docker.com/webdevops/php-nginx) which runs the Drupal 8 codebase for both local and NYPL infrastructures. Other containers are defined by docker-compose.yml which are used for local develpment only. You may modify these as per your desired configuration.

We make use of provisioning scripts for building Docker images for transfer to AWS ECR which are used by AWS ECS for running Drupal 8. NYPL's AWS containers utilize cloud services for database, file system, caching, and indexing.

## Installation

* Copy .env.example to .env
* Ensure DB_HOST matches either the container name set in `docker-compose.yml` or set to `host.docker.internal` for use with a local database server
* Populate the DB_* variables to your preferred values, if desired
* Ensure `/mysqldb-init/grants.sql` matches the user, password and database name
* Do not commit changes to the `mysqldb-init/grants.sql` file, if altered
* Database container is set to save data locally to `/mysql` so you won't lose data when restarting Docker containers via `docker-compose down` and `docker-compose up`
* Run `docker-compose up` to build the initial containers or start existing ones
* Images will be built using the `composer.json` file which should include the essential modules, themes, and libraries needed to mirror cloud development

### Prerequisites

* [Docker](https://www.docker.com); install Docker for your OS

### `composer.json`

If you are just browsing this repository on GitHub, you may notice that the files of Drupal core itself are not included in this repo.  That is because Drupal core and contrib modules are installed via Composer and ignored in the `.gitignore` file. Specific contrib modules are added to the project via `composer.json` and `composer.lock` keeps track of the exact version of each modules (or other dependency). Modules, and themes are placed in the correct directories thanks to the `"installer-paths"` section of `composer.json`. `composer.json` also includes instructions for `drupal-scaffold` which takes care of placing some individual files in the correct places like `settings.pantheon.php`.

## Test runner

Various tests including linting are performed by a PHP task runner called [Robo](https://robo.li). These tasks are defined in .travis/Robofile.php and can include setup/teardown actions including running a web server via Drush for Behat tests.

### Linting

Project conforms to PHPCS Drupal and DrupalPractice standards as provided by the [coder](https://drupal.org/project/coder) module. Any custom code must use these standards in order to pass linting tests.

### Unit tests

PHPUnit version 6.5 is used by this project to run unit tests against code in the `modules/custom` directory. Unit tests should conform to NYPL's 90% coverage minimum for all custom code written.

### Behat tests

## Updating the site

### TravisCI Requirements

#### Travis settings

* Machine token for Pantheon account for Travis
* Encrypted $MACHINE_TOKEN variable
  - Run `travis encrypt MACHINE_TOKEN=[generated machine token] --com --add env.global`
  - Allows `terminus` to interact with the Pantheon site
* Password-less SSH Key for Travis user saved on Pantheon account
* Encrypted SSH Key value for use by Travis user during build phase
  - Use `travis encrypt-file  travis-ci-key` command to encode SSH Key
  - Save encrypted file only to the repository for decoding by Travis
  - Allows the Travis user to interact with Pantheon's Git server
* Add `before_install` command to decrypt SSH Key in .travis.yml

#### Pantheon Script Settings

* Requires machine token and SSH key attached to the Pantheon account

## Git workflow
