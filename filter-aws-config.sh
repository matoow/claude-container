#!/bin/bash
# Filters an AWS INI config file, keeping only explicitly allowed sections.
# Usage: filter-aws-config.sh <input-file>
#
# Allowed sections are defined below. Add or remove entries as needed.

ALLOWED_SECTIONS=(
    "profile montu-nonprod"
    "profile montu-uk-staging"
    "profile montu-uk-test"
    "sso-session montu"
    "montu-nonprod"
    "montu-uk-staging"
)

# Build a lookup string for matching
LOOKUP=""
for s in "${ALLOWED_SECTIONS[@]}"; do
    LOOKUP="$LOOKUP|$s"
done
LOOKUP="${LOOKUP:1}"  # strip leading |

awk -v allowed="$LOOKUP" '
BEGIN {
    printing = 0
    n = split(allowed, arr, "|")
    for (i = 1; i <= n; i++) lookup[arr[i]] = 1
}
/^\[/ {
    section = $0
    gsub(/^\[|\]$/, "", section)
    if (section in lookup) {
        printing = 1
        print $0
    } else {
        printing = 0
    }
    next
}
printing { print }
' "$1"
