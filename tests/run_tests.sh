#!/usr/bin/env bash
wd=`dirname $0`
idl -IDL_STARTUP "$wd/drpStartup.pro" -e drpTest
files="$wd/**/expected/*.fits"
for file in $files
do
    outfile=`echo $file | sed -E "s|/expected/|/|"`
    fitsdiff -c SIMPLE $file $outfile
done
