# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM ruby:$RUBY_VERSION-slim

# Install dependencies (xmlsec1 para firma XMLDSIG de DTE SII)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libvips \
    pkg-config \
    postgresql-client \
    curl \
    ca-certificates \
    gnupg \
    chromium \
    fonts-liberation \
    fonts-dejavu-core \
    xmlsec1 && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Bundler version matching Gemfile.lock
RUN gem install bundler -v 4.0.5

# Set working directory
WORKDIR /app

# Grover: Node + Puppeteer + Chromium del sistema (HTML → PDF DTE)
ENV GROVER_NO_SANDBOX=true \
    GROVER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Set environment
ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle

# Copy Gemfile first for caching
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Dependencias Node para Grover (puppeteer)
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

# Copy application code
COPY . .

RUN chmod +x bin/docker-entrypoint.sh

# Expose port
EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
