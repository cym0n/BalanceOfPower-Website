#!/bin/bash

rm -f BopWeb.tgz
tar --exclude='BopWeb/metadata' --exclude='BopWeb/views/generated' --exclude='BopWeb/games' --exclude='BopWeb/test.sqlite' --exclude='BopWeb/lib/regenerate_dbix.sh' --exclude='BopWeb/testenv' -zcvf BopWeb.tgz BopWeb/
