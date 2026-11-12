# Velunori Weather

> The weather in the bar, with a forecast panel in the Velunori style.

![Weather panel with current conditions and a three-day forecast](docs/preview.png)

## Features

- The current condition as an icon in the bar; hover for temperature, condition and place.
- A panel with the temperature, a plain-language condition, feels-like, wind and humidity, and the next three days.
- Click the location to search for a city, pick a suggestion with the arrows or the mouse, or press **Automatic** to go back to detecting it from your connection.
- Units follow your setting, then the country of the report, then the system locale.
- Right-click sends the weather as a notification; middle-click refreshes.
- Existing keybindings and `omarchy-shell omarchy.weather toggle` keep working, and the stored location is the one Omarchy already uses.

## Requirements

[Velunori core](https://github.com/velunori/core) 0.4.1 or later, installed next to this plugin, and `curl`. Developed against **Omarchy 4.0.6-1**.

Forecasts come from [Open-Meteo](https://open-meteo.com) and [wttr.in](https://wttr.in), the same sources the built-in widget uses.

## Install

```bash
bash ~/dev/Velunori/weather/scripts/install-local.sh
```

The installer backs up `shell.json`, links this checkout, puts the widget where `omarchy.weather` was and restarts the shell. A failure restores the backup.

Restore the built-in weather:

```bash
bash ~/dev/Velunori/weather/scripts/restore-local.sh
```

## Configuration

Settings sit on the widget's entry in `bar.layout`, as with the built-in widget:

```json
{ "id": "velunori.weather", "unit": "metric", "refreshMinutes": 15 }
```

`unit` is `metric`, `imperial`, or left out to decide automatically.

## Development

```bash
bash scripts/check.sh
VELUNORI_TEST_LAYOUT=symlink bash scripts/check.sh
```

The check confirms `Model.js` still matches the installed Omarchy copy, tests the condition wording, lints the QML and runs an offscreen test of the panel with sample data.

Render the panel to an image:

```bash
VELUNORI_PREVIEW_PATH=/tmp/weather.png bash scripts/check.sh
VELUNORI_PREVIEW_PATH=/tmp/weather-search.png VELUNORI_PREVIEW_STATE=search bash scripts/check.sh
```

## Limits

The offscreen test draws the panel from sample data; the live fetching, the bar icon and the panel's placement have not been run in a desktop session yet. The widget has only been designed against the Velunori bar.

## Velunori plugins

Velunori is a set of independent plugins for the [Omarchy](https://omarchy.org) shell. Install only the ones you want; each lives in its own repository and can be removed without touching the others.

| Plugin | What it is |
| --- | --- |
| [core](https://github.com/velunori/core) | The Island and Orbit bars, the appearance settings and the shared design kit |
| [clock](https://github.com/velunori/clock) | Clock in the bar with a month calendar |
| [control-center](https://github.com/velunori/control-center) | Sound, displays, network, capture and reminders in one panel |
| [notifications](https://github.com/velunori/notifications) | Notification cards and a session history |
| [menu](https://github.com/velunori/menu) | The Omarchy command menu as a two-pane panel |
| [update](https://github.com/velunori/update) | A window for `omarchy update` with release notes and live progress |
| **weather** (this repository) | Weather in the bar with a forecast panel |

## License

MIT, see [LICENSE](LICENSE). The fetching and location logic is adapted from Omarchy's MIT-licensed weather panel; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
