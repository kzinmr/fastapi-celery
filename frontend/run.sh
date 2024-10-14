#!/bin/sh

envsubst '$$SERVER_URL$$APP_PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf;
nginx -g 'daemon off;';
