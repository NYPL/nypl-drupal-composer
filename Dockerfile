FROM webdevops/php-nginx:alpine-php7 AS production
MAINTAINER info@nypl.org

WORKDIR /var/www/html

ENV WEB_DOCUMENT_ROOT /var/www/html/web
ENV PHP_INI_DIR /usr/local/etc/php
ENV PHP_VERSION 7.2
ENV LD_LIBRARY_PATH /usr/local/lib

COPY ./config/drupal-*.ini /usr/local/etc/php/conf.d/
COPY ./config/cli/drupal-*.ini /usr/local/etc/php/conf.d/
# COPY ./config/nginx/*.conf /opt/docker/etc/nginx/vhost.common.d/

COPY ./ /var/www/html/

# Parallel Composer downloads
RUN composer -n global require -n "hirak/prestissimo:^0.3"

RUN composer run build-web-assets
RUN composer run apply-settings

# Ensure web/libraries are set up properly
RUN composer run verify-libs

# Setup drush and drupal console symlinks and add vendor/bin to PATH
RUN ln -s /var/www/html/vendor/bin/drush /usr/local/bin/drush
RUN ln -s /var/www/html/vendor/bin/drupal /usr/local/bin/drupal
RUN echo "export PATH=/var/www/html/vendor/bin:\$PATH" >> ~/.bash_profile

FROM production AS development

RUN composer run build-dev-assets

# RUN pecl install \
#       xdebug-2.7.2; \
#     \
#     docker-php-ext-enable \
#       xdebug;