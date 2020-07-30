#!/usr/bin/env bash

# Cache configs
php artisan config:cache
php artisan route:cache

# Perform migrations
php artisan migrate

# Create link
# from public/storage -> /var/www/storage/app/public
rm -rf public/storage
php artisan storage:link

# Generate Passport key files
php artisan passport:keys --force

exec "$@"
