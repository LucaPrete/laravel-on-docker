FROM php:7.2-fpm AS base

# Set working directory
WORKDIR /var/www

FROM base AS extensions

# Install dependencies
RUN apt-get update \
 && apt-get install --yes --no-install-recommends libpq-dev \
                                                  libmcrypt-dev \
                                                  libpng-dev \
                                                  libjpeg62-turbo-dev \
                                                  libmagickwand-dev \
                                                  wget \
                                                  zip

# Install PHP PEAR packages
RUN pecl install imagick \
                 mcrypt-1.0.1

# Install extentions
RUN docker-php-ext-install pdo pdo_pgsql
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd

# Download https://github.com/renatomefi/php-fpm-healthcheck
# to perform Kubernetes liveness and readiness healthchecks
RUN wget -O /usr/local/bin/php-fpm-healthcheck \
            https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
 && chmod +x /usr/local/bin/php-fpm-healthcheck

FROM base AS composer

ENV COMPOSER_HOME ./.composer
ENV DEBIAN_FRONTEND noninteractive

# Copy libraries from the extensions container 

COPY --from=extensions \
    /lib/x86_64-linux-gnu/libexpat.so.1 \
    /lib/x86_64-linux-gnu/libexpat.so.1

COPY --from=extensions \
    /usr/lib/libmcrypt.so.4 \
    /usr/lib/libmcrypt.so.4

COPY --from=extensions \
    /usr/lib/x86_64-linux-gnu \
    /usr/lib/x86_64-linux-gnu

COPY --from=extensions \
    /usr/local/lib/php/extensions/no-debug-non-zts-20170718 \
    /usr/local/lib/php/extensions/no-debug-non-zts-20170718

# Copy the php-fpm-healthcheck tool
COPY --from=extensions \
    /usr/local/bin/php-fpm-healthcheck \
    /usr/local/bin/php-fpm-healthcheck

RUN docker-php-ext-enable imagick
RUN docker-php-ext-enable pdo_pgsql
RUN docker-php-ext-enable mcrypt
RUN docker-php-ext-enable gd

# libfcgi0ldbl is used by php-fpm-healthcheck tool
RUN apt-get update \
    && apt-get install --yes --no-install-recommends git \
                                                     unzip \
    && apt-get install --yes libfcgi0ldbl procps \
    && rm -rf /var/lib/apt

# Install composer
COPY --from=composer:1.7.2 /usr/bin/composer /usr/bin/composer

RUN mkdir /.composer

RUN chown -R www-data:www-data /.composer
RUN chown -R www-data:www-data /var/www

FROM composer AS deps

COPY composer.json /var/www/composer.json
COPY composer.lock /var/www/composer.lock

RUN composer install --no-autoloader

FROM deps as php-fpm-custom

##### php-fpm tuning
# After emergency_restart_threshold child_processes exit
RUN sed -i 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 14/g' /usr/local/etc/php-fpm.conf
# Wait emergency_restart_interval time before exiting
RUN sed -i 's/;emergency_restart_interval = 0/emergency_restart_interval = 1m/g' /usr/local/etc/php-fpm.conf
# Time limit for child processes to wait for a reaction on signals from master
RUN sed -i 's/;process_control_timeout = 0/process_control_timeout = 10s/g' /usr/local/etc/php-fpm.conf

# Use a static number of child processes
RUN sed -i 's/pm = dynamic/pm = static/g' /usr/local/etc/php-fpm.d/www.conf
# Number of child processes pre-allocated
RUN sed -i 's/pm.max_children = 5/pm.max_children = 13/g' /usr/local/etc/php-fpm.d/www.conf

# Enable php fpm status page
RUN set -xe && echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf

FROM php-fpm-custom AS production

COPY . /var/www

# Configure Laravel - permissions
RUN chown -R www-data:www-data /var/www
RUN find /var/www -type d -exec chmod 755 {} \;
RUN find /var/www -type d -exec chmod ug+s {} \;
RUN find /var/www -type f -exec chmod 644 {} \;
RUN chmod -R ug+rwx storage bootstrap/cache

USER www-data

# Create an empty .env file to avoid errors
# Values will be read from environment variables
RUN touch .env

# Optimize Laravel configuration
RUN composer dump-autoload
RUN php artisan route:cache

# Expose port 9000 and exec startup scripts + php-fpm server
EXPOSE 9000

# Make sure the docker-entrypoint.sh is executable
RUN chmod +x /var/www/docker-entrypoint/docker-entrypoint.sh

ENTRYPOINT ["/var/www/docker-entrypoint/docker-entrypoint.sh"]
CMD ["php-fpm"]
