#!/usr/bin/env bash
shopt -s extglob
wd=`dirname $0`
idl -IDL_STARTUP "$wd/drpStartup.pro" -e drpTest
files=$(ls $wd/**/expected/*.fits)
for file in $files
do
    outfile=`echo $file | sed -E "s|/expected/|/|"`
    echo "fitsdiff -c SIMPLE $file $outfile"
    fitsdiff -c SIMPLE $file $outfile
done
