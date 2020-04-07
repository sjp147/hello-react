FROM nginx:mainline-alpine
COPY ./app/build /var/www/hello-react
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY config/nginx/default.conf /etc/nginx/conf.d/
RUN chmod g+rwx /var/cache/nginx /var/run /var/log/nginx
RUN chgrp -R root /var/cache/nginx
RUN sed -i.bak 's/^user/#user/' /etc/nginx/nginx.conf
RUN addgroup nginx root
EXPOSE 8081