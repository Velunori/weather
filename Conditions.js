// Plain-language condition for the current weather. Omarchy shows only an
// icon; the codes are the same ones its icon mapping reads.
function openMeteoText(code) {
    var c = parseInt(String(code), 10);
    if (c === 0) return "Clear";
    if (c === 1) return "Mostly clear";
    if (c === 2) return "Partly cloudy";
    if (c === 3) return "Overcast";
    if (c === 45 || c === 48) return "Fog";
    if (c >= 51 && c <= 57) return "Drizzle";
    if (c === 61 || c === 80) return "Light rain";
    if (c === 63 || c === 81) return "Rain";
    if (c === 65 || c === 82) return "Heavy rain";
    if (c === 66 || c === 67) return "Freezing rain";
    if (c === 71 || c === 85) return "Light snow";
    if (c === 73 || c === 77) return "Snow";
    if (c === 75 || c === 86) return "Heavy snow";
    if (c === 95) return "Thunderstorm";
    if (c === 96 || c === 99) return "Thunderstorm with hail";
    return "";
}

function describe(current) {
    if (!current) return "";
    if (current.openMeteoWeatherCode !== undefined && current.openMeteoWeatherCode !== null)
        return openMeteoText(current.openMeteoWeatherCode);
    // wttr.in already carries a description.
    var described = current.weatherDesc && current.weatherDesc[0] ? String(current.weatherDesc[0].value || "") : "";
    return described.replace(/^\s+|\s+$/g, "");
}

if (typeof module !== "undefined") module.exports = { openMeteoText: openMeteoText, describe: describe };
