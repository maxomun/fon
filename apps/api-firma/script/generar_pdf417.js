#!/usr/bin/env node
'use strict';

const fs = require('fs');
const bwipjs = require('bwip-js');

const inputPath = process.argv[2];
const outputPath = process.argv[3];

if (!inputPath || !outputPath) {
  console.error('Uso: node script/generar_pdf417.js <entrada.bin> <salida.png>');
  process.exit(1);
}

const data = fs.readFileSync(inputPath);

bwipjs.toBuffer(
  {
    bcid: 'pdf417',
    text: data.toString('latin1'),
    binarytext: true,
    eclevel: 5,
    columns: 18,
    scale: 2,
    height: 3,
    paddingwidth: 8,
    paddingheight: 8,
  },
  (err, png) => {
    if (err) {
      console.error(err.message || err);
      process.exit(1);
    }

    fs.writeFileSync(outputPath, png);
  }
);
