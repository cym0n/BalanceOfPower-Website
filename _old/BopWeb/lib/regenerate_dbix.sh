#!/bin/bash
#dbicdump -o dump_directory=. -o components='["InflateColumn::DateTime"]' -o overwrite_modifications=true BopWeb::BopWebDB dbi:SQLite:../test.sqlite 
dbicdump -o dump_directory=. -o components='["InflateColumn::DateTime"]' BopWeb::BopWebDB dbi:SQLite:../test.sqlite  

