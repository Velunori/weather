#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/.." && pwd -P)
core_dir="${VELUNORI_CORE_PATH:-$(dirname "$repo_dir")/core}"
layout="${VELUNORI_TEST_LAYOUT:-copy}"
[[ "$layout" == copy || "$layout" == symlink ]] || { echo 'Unknown test layout' >&2; exit 1; }
omarchy_dir="${OMARCHY_PATH:-/usr/share/omarchy}"
# Forecast parsing is shared with Omarchy unchanged; a difference means an
# Omarchy update needs to be merged into this plugin.
cmp "$repo_dir/Model.js" "$omarchy_dir/shell/plugins/panels/weather/Model.js"
[[ -n ${VELUNORI_PREVIEW_PATH:-} ]] || node "$repo_dir/tests/conditions.test.mjs"
runtime_dir=$(mktemp -d)
trap 'rm -rf "$runtime_dir"' EXIT
chmod 700 "$runtime_dir"
mkdir -p "$runtime_dir/velunori.weather" "$runtime_dir/velunori.core" "$runtime_dir/imports/qs"
cp "$repo_dir/"*.qml "$repo_dir/"*.js "$runtime_dir/velunori.weather/"
cp -r "$repo_dir/components" "$runtime_dir/velunori.weather/"
cp -r "$core_dir/kit" "$core_dir/components" "$core_dir/design" "$core_dir/assets" "$runtime_dir/velunori.core/"
if [[ "$layout" == symlink ]]; then
  mkdir "$runtime_dir/checkouts"
  mv "$runtime_dir/velunori.weather" "$runtime_dir/checkouts/weather"
  mv "$runtime_dir/velunori.core" "$runtime_dir/checkouts/core"
  ln -s core "$runtime_dir/checkouts/velunori.core"
  ln -s "$runtime_dir/checkouts/weather" "$runtime_dir/velunori.weather"
  ln -s "$runtime_dir/checkouts/core" "$runtime_dir/velunori.core"
fi
shell_dir="${OMARCHY_PATH:-/usr/share/omarchy}/shell"
for module in Commons Ui; do
  ln -s "$shell_dir/$module" "$runtime_dir/imports/qs/$module"
  ln -s "$shell_dir/$module" "$runtime_dir/$module"
done
/usr/lib/qt6/bin/qmllint -I "$runtime_dir/imports" --unqualified info --missing-property warning --incompatible-type info \
  "$runtime_dir/velunori.weather/"*.qml "$runtime_dir/velunori.weather/components/"*.qml > "$runtime_dir/lint.log" 2>&1 || { cat "$runtime_dir/lint.log"; exit 1; }
if rg -q 'Failed to import|was not found|is not a type' "$runtime_dir/lint.log"; then cat "$runtime_dir/lint.log"; exit 1; fi
cp "$repo_dir/tests/ui.qml" "$runtime_dir/shell.qml"
env -u WAYLAND_DISPLAY -u DISPLAY XDG_RUNTIME_DIR="$runtime_dir" XDG_CONFIG_HOME="$runtime_dir/config" XDG_STATE_HOME="$runtime_dir/state" XDG_CACHE_HOME="$runtime_dir/cache" \
  QML_IMPORT_PATH="$runtime_dir/imports" QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic QT_QUICK_CONTROLS_STYLE=Basic QT_QUICK_BACKEND=software \
  timeout 15s quickshell -p "$runtime_dir/shell.qml" --no-color > "$runtime_dir/ui.log" 2>&1 || { cat "$runtime_dir/ui.log"; exit 1; }
cat "$runtime_dir/ui.log"
if rg -q 'WEATHER_TEST_FAILED|Failed to load|TypeError|ReferenceError|Binding loop|Unable to assign|Ignoring unresolvable import.*velunori' "$runtime_dir/ui.log"; then exit 1; fi
if [[ -n ${VELUNORI_PREVIEW_PATH:-} ]]; then rg -q 'WEATHER_PREVIEW_SAVED' "$runtime_dir/ui.log"; exit; fi
rg -q 'WEATHER_TEST_PASSED' "$runtime_dir/ui.log"
