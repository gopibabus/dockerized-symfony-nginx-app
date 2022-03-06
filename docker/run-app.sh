#!/usr/bin/env bash

set -e

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-production}

if [ "$env" != "dev" ]; then
    echo "Removing Xdebug..."
    rm -rf /usr/local/etc/php/conf.d/{docker-php-ext-xdebug,xdebug}.ini

    # Add any additional Symfony console commands that need to run in non-development environments.
    php bin/console cache:clear --env=$env --no-debug --no-warmup
    php bin/console cache:warmup --env=$env
fi

if [ "$env" == "dev" ] && [ ! -z "$DEV_UID" ]; then
    echo "Changing www-data UID to $DEV_UID"
    echo "The UID should only be changed in development environments."
    usermod -u $DEV_UID www-data
fi

confd -onetime -backend env

# App
if [ "$role" = "app" ]; then
    
    ln -sf /etc/supervisor/conf.d-available/app.conf /etc/supervisor/conf.d/app.conf

else
    echo "Could not match the container role \"$role\""
    exit 1
fi

exec supervisord -c /etc/supervisor/supervisord.conf
