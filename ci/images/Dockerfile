# syntax=docker/dockerfile:1
# Ubuntu Noble + maintained PHP packages (including legacy 8.1), Node 22 and Composer.
# Build once per PHP minor; never install PHP from inside a CI job.
ARG PHP_VERSION=8.3
FROM node:22-bookworm-slim AS node
FROM composer:2 AS composer
FROM ubuntu:24.04 AS base
ARG PHP_VERSION
LABEL org.opencontainers.image.source="https://github.com/CodeCornTech/.github"
ENV DEBIAN_FRONTEND=noninteractive COMPOSER_ALLOW_SUPERUSER=1 NODE_PATH=/usr/local/lib/node_modules
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg software-properties-common \
      bash git zip unzip jq python3; \
    add-apt-repository -y ppa:ondrej/php; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "php${PHP_VERSION}-cli" "php${PHP_VERSION}-zip" "php${PHP_VERSION}-bcmath" \
      "php${PHP_VERSION}-intl" "php${PHP_VERSION}-mbstring" \
      "php${PHP_VERSION}-sqlite3" "php${PHP_VERSION}-pgsql" \
      "php${PHP_VERSION}-mysql" "php${PHP_VERSION}-xml" \
      "php${PHP_VERSION}-curl"; \
    ln -s "/usr/bin/php${PHP_VERSION}" /usr/local/bin/php; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && php -v && node -v && npm -v && composer --version
WORKDIR /workspace

FROM base AS ci

FROM base AS playwright
ARG PLAYWRIGHT_VERSION=1.62.1
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    PLAYWRIGHT_MODULE=/usr/local/lib/node_modules/playwright
RUN npm install --global "playwright@${PLAYWRIGHT_VERSION}" \
    && npx playwright install --with-deps chromium \
    && node -e 'require(process.env.PLAYWRIGHT_MODULE).chromium.executablePath()'
