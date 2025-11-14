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

ZIPFILE=$(mktemp)
mkdir -p "$(dirname "$ZIPFILE")/datasets"
cp "$TEMP_DIR"/* "$(dirname "$ZIPFILE")/datasets/"
cd "$(dirname "$ZIPFILE")" && zip -r "$ZIPFILE".zip datasets

# publish ZIP file
rsync -av "$ZIPFILE".zip "$TARGET_SRV":"$TARGET_DIR"/datasets.zip

# cleanup
rm -rf "$TEMP_DIR" "$ZIPFILE" "$(dirname "$ZIPFILE")/datasets"
