#!/bin/bash
cd /var/www/mbs.mozzam.co.za/lovable/_next/static/chunks || exit 0
for f in *_dpl=*; do
  [ -e "$f" ] || continue
  target="${f%%_dpl=*}"
  echo mv "$f" "$target"
  mv -f "$f" "$target"
done
rm -f *\?* || true
ls -la
