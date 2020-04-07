FROM bitnami/nginx:latest
COPY ./app/build /var/www/hello-react
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN chgrp -R 0 /var/cache/nginx && \
    chmod -R g=u /var/cache/nginx