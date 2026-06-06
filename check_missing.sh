#!/bin/bash

dst=/var/www/mbs.mozzam.co.za/lovable
while IFS= read -r p; do
  if [ -z "$p" ]; then
    continue
  fi
  if [ ! -f "$dst$p" ]; then
    echo MISSING:$p
  fi
done < /tmp/assets_clean.txt

echo DONE
