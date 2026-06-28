#!/bin/bash
set -e

# Con volumen .:/app, node_modules vive en el host; asegurar puppeteer al arrancar.
if [ ! -d node_modules/puppeteer ] || [ ! -d node_modules/bwip-js ]; then
  echo "Instalando dependencias Node (puppeteer, bwip-js) para PDF DTE..."
  npm install --omit=dev
fi

exec "$@"
