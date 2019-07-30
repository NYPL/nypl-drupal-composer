FROM php:7.2-fpm-alpine AS production
MAINTAINER nypl

WORKDIR /var/www/html

ENV PHP_INI_DIR /usr/local/etc/php
ENV PHP_VERSION 7.2
ENV LD_LIBRARY_PATH /usr/local/lib

ARG PECL_HTTP_PROXY

RUN apk add --update --no-cache --virtual .dd-build-deps \
      libpng-dev \
      libjpeg-turbo-dev \
      postgresql-dev \
      libxml2-dev \
      $PHPIZE_DEPS; \
    \
    docker-php-ext-configure gd \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/;  \
    docker-php-ext-install -j$(nproc) gd; \
    \
    docker-php-ext-install \
      mbstring \
      pdo_mysql \
      pdo_pgsql \
      zip; \
    \
    docker-php-ext-install \
      opcache \
      bcmath \
      soap; \
    \
    # Uploadprogress.
    mkdir -p /usr/src/php/ext/uploadprogress; \
    up_url="https://github.com/wodby/pecl-php-uploadprogress/archive/latest.tar.gz"; \
    wget -qO- "${up_url}" | tar xz --strip-components=1 -C /usr/src/php/ext/uploadprogress; \
    docker-php-ext-install uploadprogress; \
    \
    # Install composer
    curl -sS https://getcomposer.org/installer | php; \
    chmod +x composer.phar; \
    mv composer.phar /usr/local/bin/composer; \
    composer global require hirak/prestissimo --no-plugins --no-scripts; \
    \
    # Install drush
    curl -L -o drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.4.2/drush.phar; \
    chmod +x drush.phar; \
    mv drush.phar /usr/local/bin/drush; \
    # Install Drupal console
    \
    curl -L -o drupal.phar https://drupalconsole.com/installer; \
    chmod +x drupal.phar; \
    mv drupal.phar /usr/local/bin/drupal; \
    echo "export PATH=~/.composer/vendor/bin:\$PATH" >> ~/.bash_profile; \
    \
    apk add --no-cache \
      sudo \
      git \
      less \
      libpng \
      libjpeg \
      libpq \
      libxml2 \
      mysql-client \
      openssh-client \
      rsync \
      patch; \
    \
    pecl config-set php_ini "${PHP_INI_DIR}/php.ini"; \
    if [[ -n "${PECL_HTTP_PROXY}" ]]; then \
        # Using pear as pecl throw errors: https://blog.flowl.info/2015/peclpear-behind-proxy-how-to/
        pear config-set http_proxy "${PECL_HTTP_PROXY}"; \
    fi; \
    \
    pecl install \
      xdebug-2.7.2; \
    \
    docker-php-ext-enable \
      xdebug; \
    \
    apk del .dd-build-deps;

COPY config/drupal-*.ini /usr/local/etc/php/conf.d/
COPY config/cli/drupal-*.ini /usr/local/etc/php/conf.d/

COPY ./ /var/www/html/

# Set a random salt and save to a file for Drupal's hash setting.
RUN touch /usr/local/var/salt.txt
RUN date +%s | sha256sum | base64 | head -c 32 > /usr/local/var/salt.txt
RUN chmod 0400 /usr/local/var/salt.txt

# Copy our local settings and services to the file system for ScriptHandler.php checks and placement
COPY ./config/settings.php /tmp
COPY ./config/settings.local.php /tmp
COPY ./config/services.yml /tmp

RUN /usr/local/bin/composer install --prefer-source --no-interaction

FROM production AS development
