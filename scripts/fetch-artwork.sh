#!/usr/bin/env bash
#
# Downloads Logitech's product renders for the devices attached to THIS machine,
# into this user's OpenGHub data directory.
#
#   ./scripts/fetch-artwork.sh              # every connected Logitech device
#   ./scripts/fetch-artwork.sh c08d 407f    # specific product ids
#   ./scripts/fetch-artwork.sh c08d https://…/some-render.png   # explicit URL
#
# The images stay on your machine and are never redistributed with OpenGHub:
# they remain Logitech's copyright. This script only automates what you could do
# by right-clicking the image on logitechg.com and saving it.
#
# Nothing is downloaded for a device not listed in src-tauri/data/artwork-sources.tsv — drop a PNG
# named <product-id>.png into the target directory by hand instead.
#
# Per-zone lighting masks are not downloadable: G HUB fetches them per device
# from its own depot service, keyed by `render_icon_key` in the device schema.
# If you have them, name them <product-id>-zone<N>.png alongside the base render
# and OpenGHub will use the alpha channel as a mask.

set -euo pipefail

# Must match artwork::dir() in src-tauri/src/artwork.rs — lowercase.
DEST="${OPENGHUB_ARTWORK_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/openghub/devices}"
# Shared with the app (src-tauri/src/artwork.rs): product id, site, path.
SOURCES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/src-tauri/data/artwork-sources.tsv"
# Cloudinary transform: cap the width, force PNG. No d_... default image, so a
# wrong path is a 404 instead of a blank placeholder.
TRANSFORM="w_1200,c_limit,q_auto,f_png"

# product id -> full URL
declare -A ART=()
while IFS=$'\t' read -r id site path; do
  [[ -z "$id" || "$id" == \#* ]] && continue
  case "$site" in
    g) ART[${id,,}]="https://resource.logitechg.com/$TRANSFORM/content/dam/gaming/en/products/$path" ;;
    l) ART[${id,,}]="https://resource.logitech.com/$TRANSFORM/content/dam/logitech/en/products/$path" ;;
  esac
done < "$SOURCES"

mkdir -p "$DEST"

download() {
  local id="$1" url="$2" out="$DEST/$1.png"
  printf '  %-6s ' "$id"
  if curl -sfL --max-time 30 -o "$out.part" "$url"; then
    # Check it is a real image, not an error page or the CDN's tiny blank PNG.
    if head -c4 "$out.part" | grep -q $'\x89PNG' && [[ $(stat -c %s "$out.part") -ge 2048 ]]; then
      mv "$out.part" "$out"
      echo "OK  -> $out"
      return 0
    fi
    echo "FAILED (not a PNG — the path is probably wrong)"
  else
    echo "FAILED (download error)"
  fi
  rm -f "$out.part"
  return 1
}

# Explicit "<id> <url>" pair.
if [[ $# -eq 2 && "$2" == http* ]]; then
  echo "Saving to $DEST"
  download "$1" "$2"
  exit $?
fi

if [[ $# -gt 0 ]]; then
  ids=("$@")
else
  # Read HID-level product ids from sysfs rather than lsusb: a device behind a
  # Unifying/LIGHTSPEED receiver reports the *receiver's* id on the USB bus, but
  # its own id at the HID layer — which is the one the artwork is keyed on.
  mapfile -t ids < <(
    cat /sys/class/hidraw/hidraw*/device/uevent 2>/dev/null |
      grep -oiE '^HID_ID=[0-9a-f]+:0+046D:0+([0-9A-F]{4})' |
      sed -E 's/.*:0+([0-9A-F]{4})$/\1/' |
      tr 'A-Z' 'a-z' | sort -u
  )
  if [[ ${#ids[@]} -eq 0 ]]; then
    echo "No Logitech devices found." >&2
    echo "Pass product ids explicitly, e.g. $0 c08d" >&2
    exit 1
  fi
  echo "Found ${#ids[@]} connected Logitech device(s): ${ids[*]}"
fi

echo "Saving to $DEST"
missing=()
for id in "${ids[@]}"; do
  id="${id,,}"
  if [[ -n "${ART[$id]:-}" ]]; then
    download "$id" "${ART[$id]}" || missing+=("$id")
  else
    printf '  %-6s not in the table\n' "$id"
    missing+=("$id")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  cat <<EOF

No image for: ${missing[*]}
Find the product on logitechg.com or logitech.com, right-click its render, and save it as
  $DEST/<product-id>.png
Then add a line to src-tauri/data/artwork-sources.tsv so it works next time.
EOF
fi
