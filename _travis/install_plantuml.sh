#!/bin/bash
set -e

if [ ! -f /tmp/plantuml_7707-1_all ]; then
    wget --retry-connrefused --no-check-certificate http://yar.fruct.org/attachments/download/362/plantuml_7707-1_all.deb
    dpkg -i plantuml_7707-1_all.deb
    rm -rf plantuml_7707-1_all*
    touch /tmp/plantuml_7707-1_all
fi