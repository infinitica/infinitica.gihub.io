#!/bin/bash
set -e

if [ ! -f /tmp/tidy-html5 ]; then
    git clone https://github.com/htacg/tidy-html5.git
    cd tidy-html5/build/cmake
    git checkout 5.1.25
    cmake ../..
    make
    make install
    cd ../../..
    rm -rf tidy-html5
    touch /tmp/tidy-html5
fi