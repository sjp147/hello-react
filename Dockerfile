FROM bitnami/nginx:latest
COPY ./app/build /var/www/hello-react
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN chmod g+rwx /var/cache/nginx /var/run /var/log/nginx
EXPOSE 8081