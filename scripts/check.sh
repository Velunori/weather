#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/.." && pwd -P)
core_dir="${VELUNORI_CORE_PATH:-$(dirname "$repo_dir")/core}"
layout="${VELUNORI_TEST_LAYOUT:-copy}"
[[ "$layout" == copy || "$layout" == symlink ]] || { echo 'Unknown test layout' >&2; exit 1; }
omarchy_dir="${OMARCHY_PATH:-/usr/share/omarchy}"
# Velunori extends Omarchy's daily parser to seven future days.
if [[ -z ${VELUNORI_PREVIEW_PATH:-} ]]; then
  node "$repo_dir/tests/conditions.test.mjs"
  node "$repo_dir/tests/forecast.test.mjs"
  python3 -m unittest discover -s "$repo_dir/tests" -p 'test_*.py'
fi
runtime_dir=$(mktemp -d)
trap 'rm -rf "$runtime_dir"' EXIT
chmod 700 "$runtime_dir"
mkdir -p "$runtime_dir/velunori.weather" "$runtime_dir/velunori.core" "$runtime_dir/imports/qs"
cp "$repo_dir/"*.qml "$repo_dir/"*.js "$runtime_dir/velunori.weather/"
cp "$repo_dir/cities.py" "$runtime_dir/velunori.weather/"
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
# Race active-city writes and forecast responses using stand-ins only.
mkdir -p "$runtime_dir/bin" "$runtime_dir/home/.local/state/omarchy/settings"
cat > "$runtime_dir/bin/omarchy-weather-location" <<'PY'
#!/usr/bin/env python3
import json, os, sys, time
from pathlib import Path
path=Path(os.environ['HOME'])/'.local/state/omarchy/settings/weather.json'
time.sleep(.08)
if sys.argv[1]=='--clear': value={'name':'','latitude':None,'longitude':None}
else:
    lat,lon=map(float,sys.argv[3].split(','))
    value={'name':sys.argv[2],'latitude':lat,'longitude':lon}
path.write_text(json.dumps(value))
PY
cat > "$runtime_dir/bin/curl" <<'PY'
#!/usr/bin/env python3
import json, sys, time
from urllib.parse import urlparse,parse_qs
url=sys.argv[-1]
if 'api.open-meteo.com' in url:
    lat=float(parse_qs(urlparse(url).query)['latitude'][0])
    time.sleep(.02 if lat<40 else .3)
    print(json.dumps({'current':{'temperature_2m':33 if lat<40 else 11,'apparent_temperature':10,'relative_humidity_2m':50,'wind_speed_10m':10,'weather_code':2,'is_day':1},'daily':{'time':[]}}))
elif 'format=j1' in url:
    print(json.dumps({'current_condition':[{'temp_C':'5','temp_F':'41','weatherCode':'116'}]}))
else: print('Automatic')
PY
chmod +x "$runtime_dir/bin/omarchy-weather-location" "$runtime_dir/bin/curl"
mkdir -p "$runtime_dir/state/velunori/weather"
cat > "$runtime_dir/state/velunori/weather/cities.json" <<'JSON'
[{"id":"paris","name":"Paris","latitude":48.86,"longitude":2.35},{"id":"tokyo","name":"Tokyo","latitude":35.68,"longitude":139.69}]
JSON
cp "$repo_dir/tests/data.qml" "$runtime_dir/shell.qml"
env -u WAYLAND_DISPLAY -u DISPLAY PATH="$runtime_dir/bin:$PATH" HOME="$runtime_dir/home" XDG_RUNTIME_DIR="$runtime_dir" XDG_CONFIG_HOME="$runtime_dir/config" XDG_STATE_HOME="$runtime_dir/state" \
  QML_IMPORT_PATH="$runtime_dir/imports" QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic QT_QUICK_CONTROLS_STYLE=Basic QT_QUICK_BACKEND=software \
  timeout 10s quickshell -p "$runtime_dir/shell.qml" --no-color > "$runtime_dir/data.log" 2>&1 || { cat "$runtime_dir/data.log"; exit 1; }
cat "$runtime_dir/data.log"
rg -q 'WEATHER_CITY_SWITCH_PASSED' "$runtime_dir/data.log"
if rg -q 'WEATHER_CITY_SWITCH_FAILED|ReferenceError|TypeError|Binding loop|Unable to assign' "$runtime_dir/data.log"; then exit 1; fi
python3 - "$runtime_dir/home/.local/state/omarchy/settings/weather.json" <<'PY'
import json,sys
assert json.load(open(sys.argv[1]))['name']=='Tokyo', 'Last city selection must win on disk'
PY
