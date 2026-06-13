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
    xmlsec1 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Bundler version matching Gemfile.lock
RUN gem install bundler -v 4.0.5

# Set working directory
WORKDIR /app

# Set environment
ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle

# Copy Gemfile first for caching
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
