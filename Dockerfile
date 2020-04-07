FROM nginx:latest
COPY ./app/build /var/www/hello-react
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN sudo chown -R nginx.nginx /var/cache/nginx/client_temp 