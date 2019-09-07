#!/bin/bash
set -e

if [ ! -f /tmp/sfnt2woff ]; then
wget http://img.teamed.io/woff-code-latest.zip
unzip woff-code-latest.zip -d sfnt2woff
cd sfnt2woff
make
mv sfnt2woff /usr/local/bin/
cd ..
rm -rf sfnt2woff woff-code-latest*
touch /tmp/sfnt2woff
fi