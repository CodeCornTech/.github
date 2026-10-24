# syntax=docker/dockerfile:1
# Reusable PHP + Node 22 toolchain, never install PHP in a CI job.
ARG PHP_VERSION=8.3
FROM node:22-bookworm-slim AS node
FROM composer:2 AS composer
FROM php:${PHP_VERSION}-cli-bookworm
LABEL org.opencontainers.image.source="https://github.com/CodeCornTech/.github"
ENV DEBIAN_FRONTEND=noninteractive COMPOSER_ALLOW_SUPERUSER=1 NODE_PATH=/usr/local/lib/node_modules
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends bash git curl ca-certificates unzip zip jq python3 libzip-dev libicu-dev libonig-dev libpq-dev libsqlite3-dev; \
    docker-php-ext-install -j 2 bcmath intl mbstring pdo_mysql pdo_pgsql pdo_sqlite zip; \
    apt-get clean; rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && php -v && node -v && npm -v && composer --version
WORKDIR /workspace
