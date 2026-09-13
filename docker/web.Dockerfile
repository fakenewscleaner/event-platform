ARG APP_IMAGE=event-platform-app:local
FROM ${APP_IMAGE} AS app
FROM nginx:stable-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=app /var/www/html/public /var/www/html/public
