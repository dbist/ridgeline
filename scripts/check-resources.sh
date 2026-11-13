#!/usr/bin/env bash
# Cross-checks resource ids that only the compiler would otherwise catch, and
# CI cannot compile (issue #1). Plain grep over tracked files: no SDK needed.
# Prints one line per problem and exits non-zero if there are any.
#
# Run from the repository root: scripts/check-resources.sh
set -euo pipefail

cd "$(dirname "$0")/.."

STRINGS=resources/strings/strings.xml
PROPERTIES=resources/properties.xml
SETTINGS=resources/settings/settings.xml
DRAWABLES=resources/drawables/drawables.xml

problems=0
report() {
    echo "$1"
    problems=$((problems + 1))
}

# Tracked resource XML and the manifest: where @Strings/@Drawables refs live.
xml_files() {
    { echo manifest.xml; git ls-files 'resources/*.xml'; } | sort
}

# Every NAME after a prefix like "@Strings." in the given files, one per line.
refs() {
    local prefix=$1; shift
    { grep -ohE "${prefix}[A-Za-z0-9_]+" "$@" || true; } | sed "s/^${prefix}//" | sort -u
}

# Every id="NAME" on lines containing <tag in a file.
ids() {
    local tag=$1 file=$2
    { grep -oE "<${tag}[^>]*id=\"[^\"]+\"" "$file" || true; } |
        sed -E 's/.*id="([^"]+)".*/\1/' | sort -u
}

# First-argument string literals of the named function calls in source/.
call_keys() {
    local fn
    for fn in "$@"; do
        { grep -ohE "${fn}\(\"[A-Za-z0-9_]+\"" source/*.mc || true; } |
            sed -E 's/.*\("([^"]+)"/\1/'
    done | sort -u
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- strings ---------------------------------------------------------------
ids string "$STRINGS" > "$tmp/strings"
# shellcheck disable=SC2046
refs '@Strings\.' $(xml_files) > "$tmp/xml_string_refs"
{ cat "$tmp/xml_string_refs"; refs 'Rez\.Strings\.' source/*.mc; } | sort -u > "$tmp/string_refs"

comm -23 "$tmp/string_refs" "$tmp/strings" | while read -r name; do
    echo "undefined string: @Strings.$name / Rez.Strings.$name has no <string id=\"$name\"> in $STRINGS"
done > "$tmp/out_strings_undefined"
comm -13 "$tmp/string_refs" "$tmp/strings" | while read -r name; do
    echo "unused string: <string id=\"$name\"> in $STRINGS is never referenced"
done > "$tmp/out_strings_unused"

# --- properties ------------------------------------------------------------
ids property "$PROPERTIES" > "$tmp/properties"
refs '@Properties\.' "$SETTINGS" > "$tmp/property_refs"
comm -23 "$tmp/property_refs" "$tmp/properties" | while read -r name; do
    echo "undefined property: @Properties.$name in $SETTINGS has no <property id=\"$name\"> in $PROPERTIES"
done > "$tmp/out_props_undefined"

# --- setting keys in source ------------------------------------------------
# Read by the view: getSetting("X", ...) plus the column keys, which are
# read in a loop from RidgelineMetrics.COLUMN_KEYS.
{
    call_keys getSetting
    { grep -hE 'COLUMN_KEYS *=' source/*.mc || true; } | grep -oE '"[A-Za-z0-9_]+"' | tr -d '"'
} | sort -u > "$tmp/read_keys"
# Any key the source names: the reads above plus the on-watch menu's calls.
{
    cat "$tmp/read_keys"
    call_keys ridgelineGetProperty ridgelineSetProperty
    { grep -ohE 'openPicker\([A-Za-z]+, *"[A-Za-z0-9_]+"' source/*.mc || true; } |
        sed -E 's/.*"([^"]+)"/\1/'
} | sort -u > "$tmp/source_keys"

comm -23 "$tmp/source_keys" "$tmp/properties" | while read -r name; do
    echo "unknown setting key: \"$name\" is used in source/ but has no <property id=\"$name\"> in $PROPERTIES"
done > "$tmp/out_keys_unknown"
comm -13 "$tmp/read_keys" "$tmp/properties" | while read -r name; do
    echo "unread setting: <property id=\"$name\"> in $PROPERTIES is never read by getSetting or COLUMN_KEYS"
done > "$tmp/out_keys_unread"

# --- drawables -------------------------------------------------------------
ids bitmap "$DRAWABLES" > "$tmp/drawables"
# shellcheck disable=SC2046
refs '@Drawables\.' $(xml_files) > "$tmp/drawable_refs"
comm -23 "$tmp/drawable_refs" "$tmp/drawables" | while read -r name; do
    echo "undefined drawable: @Drawables.$name has no id=\"$name\" in $DRAWABLES"
done > "$tmp/out_drawables_undefined"
{ grep -oE 'filename="[^"]+"' "$DRAWABLES" || true; } | sed -E 's/filename="([^"]+)"/\1/' |
    while read -r file; do
        if [ ! -f "resources/drawables/$file" ]; then
            echo "missing drawable file: $DRAWABLES names $file, but resources/drawables/$file does not exist"
        fi
    done > "$tmp/out_drawables_missing"

# --- report ----------------------------------------------------------------
for f in "$tmp"/out_*; do
    while read -r line; do
        report "$line"
    done < "$f"
done

if [ "$problems" -gt 0 ]; then
    echo "$problems resource problem(s)"
    exit 1
fi
echo "resources consistent: $(wc -l < "$tmp/strings" | tr -d ' ') strings, $(wc -l < "$tmp/properties" | tr -d ' ') properties, $(wc -l < "$tmp/drawables" | tr -d ' ') drawables"
