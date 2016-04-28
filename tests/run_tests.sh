#!/usr/bin/env bash
idl -e drpTest
files="tests/**/expected/*.fits"
for file in $files
do
    outfile=`echo $file | sed -E "s|/expected/|/|"`
    fitsdiff-ap -c SIMPLE $file $outfile
done
