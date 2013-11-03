#!/usr/bin/env bash

if ! [ -d "nikola" ]; then
    virtualenv nikola  --python=python2.7
    source nikola/bin/activate
    pip install requests
    #sudo yum instal  qlibxslt-devel libxml2-devel
    pip install nikola

else
    source nikola/bin/activate
fi
