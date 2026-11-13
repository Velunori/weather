# Omarchy

`WeatherData.qml` is adapted from the installed Omarchy 4.0.6-1 weather panel
(`shell/plugins/panels/weather/Panel.qml`): fetching, retries, unit selection
and location editing originate there. `Model.js` is adapted from the same directory, with its daily forecast limit
extended from three to seven future days.

Copyright (c) David Heinemeier Hansson. MIT license included in `LICENSE`.
Upstream: https://github.com/basecamp/omarchy.

Velunori owns the panel presentation, saved-city storage, city-switch serialization, response identity checks, the bar widget and the condition wording.
Installed `qs.Commons` and `qs.Ui` modules remain owned by Omarchy.
