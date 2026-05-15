#!/bin/bash
# Total Respec - full build pipeline.
#
# Usage:
#   bash build.sh             - build to dist/Total Respec/
#   bash build.sh --deploy    - also copy into MO2 mods/Total Respec/
#
# Required tools:
#   .NET 9 SDK on PATH                (Mutagen ESP build)
#   Caprica                           (Papyrus .psc -> .pex)
#   JContainers SE installed in MO2   (Papyrus headers for JSON config reads)
#
# Override defaults via env:
#   CAPRICA       path to Caprica.exe          [default: ../../Caprica/Caprica.exe]
#   HEADERS       Papyrus header dir           [default: ../_shared/papyrus-headers]
#   JCONTAINERS   JContainers psc source dir   [default: <MO2 mods>/JContainers SE/scripts/source]
#   DEPLOY_TO     MO2 mod folder               [default: /c/Games/Skyrim Essentials/mods/Total Respec]
set -e

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TK_ROOT="$(cd "$PROJ/../.." && pwd)"

CAPRICA="${CAPRICA:-$TK_ROOT/../Caprica/Caprica.exe}"
HEADERS="${HEADERS:-$PROJ/../_shared/papyrus-headers}"
JCONTAINERS="${JCONTAINERS:-/c/Games/Skyrim Essentials/mods/JContainers SE/scripts/source}"
DEPLOY_TO="${DEPLOY_TO:-/c/Games/Skyrim Essentials/mods/Total Respec}"

DIST="$PROJ/dist"
STAGE="$DIST/Total Respec"

fail() { echo "ERROR: $1" >&2; exit 1; }
command -v dotnet >/dev/null     || fail "dotnet not found on PATH (need .NET 9 SDK)"
[ -f "$CAPRICA" ]                || fail "Caprica not found at: $CAPRICA"
[ -d "$HEADERS/Source" ]         || fail "Papyrus headers not found at: $HEADERS/Source"
[ -d "$JCONTAINERS" ]            || fail "JContainers headers not found at: $JCONTAINERS — is JContainers SE installed?"

echo "==> Cleaning dist/"
rm -rf "$DIST"
mkdir -p "$STAGE/Scripts/Source"
mkdir -p "$STAGE/SKSE/Plugins"

echo "==> Compiling Papyrus scripts (with JContainers headers on the import path)"
cd "$PROJ/scripts"
"$CAPRICA" --game skyrim \
    -i "$HEADERS/Source" \
    -i "$JCONTAINERS" \
    -f "$HEADERS/TESV_Papyrus_Flags.flg" \
    -o "$STAGE/Scripts" \
    TR_RenewalEffect.psc 2>&1 | tail -5
cp TR_RenewalEffect.psc "$STAGE/Scripts/Source/"
cd "$PROJ"

echo "==> Staging JSON config"
cp "$PROJ/config/TotalRespec.json" "$STAGE/SKSE/Plugins/"

echo "==> Building ESP (Mutagen via dotnet)"
cd "$PROJ/esp/EspBuilder/EspBuilder"
dotnet build -c Release 2>&1 | tail -3
dotnet run -c Release --no-build -- "$STAGE" 2>&1 | tail -5
cd "$PROJ"

echo "==> Built:"
find "$STAGE" -type f -printf "    %p  (%s bytes)\n"

if [ "$1" = "--deploy" ]; then
    [ -n "$DEPLOY_TO" ] || fail "DEPLOY_TO not set"
    echo "==> Deploying to $DEPLOY_TO"
    mkdir -p "$DEPLOY_TO"
    cp -r "$STAGE/." "$DEPLOY_TO/"
    echo "==> Deployed. F5 in MO2 to refresh."
fi

echo "==> Done."
