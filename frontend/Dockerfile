FROM nginx

COPY dist /usr/share/nginx/html
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template

COPY run.sh /app/run.sh

EXPOSE 5174

# run run.sh
CMD [ "sh", "/app/run.sh" ]
