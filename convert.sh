#!/bin/bash

mkdir -p csv/
for file in json/*-adcs.json; do
  output=csv/"$(basename -s .json $file).csv"
  jq -r -f adcs2csv.jq "$file" >"$output"
done

