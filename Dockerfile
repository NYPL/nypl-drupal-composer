FROM webdevops/php-nginx:alpine-php7 AS production
MAINTAINER info@nypl.org

WORKDIR /var/www/html

ENV WEB_DOCUMENT_ROOT /var/www/html/web
ENV PHP_INI_DIR /usr/local/etc/php
ENV PHP_VERSION 7.2
ENV LD_LIBRARY_PATH /usr/local/lib

COPY config/drupal-*.ini /usr/local/etc/php/conf.d/
COPY config/cli/drupal-*.ini /usr/local/etc/php/conf.d/

COPY ./ /var/www/html/

ARG USER_GROUP_ID=1000
ARG USER_ID=1000

# Copy our local settings and services to the file system for ScriptHandler.php checks and placement
COPY ./config/settings.php /tmp
COPY ./config/settings.local.php /tmp
COPY ./config/services.yml /tmp

# Set a random salt and save to a file for Drupal's hash setting.
RUN touch /usr/local/share/salt.txt
RUN date +%s | sha256sum | base64 | head -c 32 > /usr/local/share/salt.txt
RUN chmod 0444 /usr/local/share/salt.txt
RUN chown nginx:www-data /usr/local/share/salt.txt
RUN COMPOSER_MEMORY_LIMIT=2G composer install --prefer-source --no-interaction --no-dev

# Set nginx as the owner/group of the webapp
RUN chown -R nginx:www-data /var/www/html

# Clean up /tmp files
RUN rm /tmp/*

FROM production AS development

# RUN /usr/local/bin/composer install --prefer-source --no-interaction

# RUN pecl install \
#       xdebug-2.7.2; \
#     \
#     docker-php-ext-enable \
#       xdebug;