FROM ubuntu:24.04 AS build

ARG FLUTTER_VERSION=3.44.8
ARG FLUTTER_ARCHIVE_SHA256=672089e001571a9fbb209a495c583580c0c6c73ef98999264ba07fa93ace332d

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    libglu1-mesa \
    unzip \
    xz-utils \
    zip \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz \
  && echo "${FLUTTER_ARCHIVE_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
  && tar -xf /tmp/flutter.tar.xz -C /opt \
  && rm /tmp/flutter.tar.xz

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

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