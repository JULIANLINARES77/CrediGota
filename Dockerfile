FROM ghcr.io/cirruslabs/flutter:3.44.8 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --base-href=/

FROM nginx:1.27-alpine AS web

ENV PORT=10000
ENV NGINX_ENVSUBST_FILTER=^PORT$

COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:$PORT/" >/dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]