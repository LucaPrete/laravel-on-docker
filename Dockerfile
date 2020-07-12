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
                                                  zip

# Install PHP PEAR packages
RUN pecl install imagick \
                 mcrypt-1.0.1

# Install extentions
RUN docker-php-ext-install pdo pdo_pgsql
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd

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

RUN docker-php-ext-enable imagick
RUN docker-php-ext-enable pdo_pgsql
RUN docker-php-ext-enable mcrypt
RUN docker-php-ext-enable gd

RUN apt-get update \
    && apt-get install --yes --no-install-recommends git \
                                                     unzip \
    && rm -rf /var/lib/apt

# Install composer
COPY --from=composer:1.7.2 /usr/bin/composer /usr/bin/composer

RUN mkdir /.composer

RUN chown -R www-data:www-data /.composer
RUN chown -R www-data:www-data /var/www

FROM composer AS deps

COPY composer.json /var/www/composer.json
COPY composer.lock /var/www/composer.lock

RUN composer install --no-dev --no-autoloader

FROM deps AS production

COPY . /var/www

# Configure Laravel - permissions
RUN chown -R www-data:www-data /var/www
RUN find /var/www -type d -exec chmod 755 {} \;
RUN find /var/www -type d -exec chmod ug+s {} \;
RUN find /var/www -type f -exec chmod 644 {} \;
RUN chmod -R ug+rwx storage bootstrap/cache

USER www-data

# Optimize Laravel configuration
RUN composer dump-autoload
RUN php artisan config:cache

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
