#!/usr/bin/env bash
idl -e drpTest
wd=`dirname $0`
files="$wd/**/expected/*.fits"
for file in $files
do
    outfile=`echo $file | sed -E "s|/expected/|/|"`
    fitsdiff -c SIMPLE $file $outfile
done
