#!/bin/bash

cd "$(dirname "$0")/.."

TARGET_SRV=kaskade
TARGET_DIR="/var/www/textplus"

TEMP_DIR=$(mktemp -d)

for i in dta/*.yml dwds/*.yml; do
  perl schemata/dta2textplus.pl -i "$i" | jq -M . > "$TEMP_DIR"/$(basename "$i" .yml).json
done

# delete all zero-size files in $TEMP_DIR
find "$TEMP_DIR" -type f -size 0 -delete

# publish JSON files
rsync -av "$TEMP_DIR"/ "$TARGET_SRV":"$TARGET_DIR"/datasets
ssh "$TARGET_SRV" "chmod 755 '$TARGET_DIR'/datasets"

# publish LR CMDI files
rsync -av lex-res/*.xml "$TARGET_SRV":"$TARGET_DIR"/datasets-lr

# generate ZIP file for collections
ZIPFILE=$(mktemp)
mkdir -p "$(dirname "$ZIPFILE")/datasets"
cp "$TEMP_DIR"/* "$(dirname "$ZIPFILE")/datasets/"
(cd "$(dirname "$ZIPFILE")" && zip -r "$ZIPFILE".zip datasets)

# publish ZIP file
rsync -av "$ZIPFILE".zip "$TARGET_SRV":"$TARGET_DIR"/datasets.zip

# generate ZIP file for lexical resources
ZIPFILE_LR=$(mktemp)
mkdir -p "$(dirname "$ZIPFILE_LR")/datasets-lr"
cp "lex-res"/*.xml "$(dirname "$ZIPFILE_LR")/datasets-lr/"
(cd "$(dirname "$ZIPFILE_LR")" && zip -r "$ZIPFILE_LR".zip datasets-lr)

# publish ZIP files
rsync -av "$ZIPFILE".zip "$TARGET_SRV":"$TARGET_DIR"/datasets.zip
rsync -av "$ZIPFILE_LR".zip "$TARGET_SRV":"$TARGET_DIR"/datasets-lr.zip

# cleanup
rm -rf "$TEMP_DIR" "$ZIPFILE" "$ZIPFILE_LR" "$(dirname "$ZIPFILE")/datasets" "$(dirname "$ZIPFILE")/datasets-lr"
