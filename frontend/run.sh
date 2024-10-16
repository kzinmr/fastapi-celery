#!/bin/sh
echo "BACKEND_URL: $BACKEND_URL"
echo "APP_PORT: $APP_PORT"

envsubst '$$BACKEND_URL $$APP_PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf;
cat /etc/nginx/conf.d/default.conf
nginx -g 'daemon off;';
