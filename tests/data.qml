//@ pragma OmarchyLoadPatch
import QtQuick
import Quickshell
import "velunori.weather" as W
ShellRoot {
    W.WeatherData { id: weather; settings: ({unit:"metric"}) }
    W.WeatherData { id: paris; fixedLocation: ({name:"Paris",latitude:48.86,longitude:2.35}); settings: ({unit:"metric"}) }
    W.WeatherData { id: tokyo; fixedLocation: ({name:"Tokyo",latitude:35.68,longitude:139.69}); settings: ({unit:"metric"}) }
    Timer {
        interval: 100; running: true
        onTriggered: {
            weather.selectCity({name:"Paris",latitude:48.86,longitude:2.35});
            weather.selectCity({name:"Berlin",latitude:52.52,longitude:13.4});
            weather.selectCity({name:"Tokyo",latitude:35.68,longitude:139.69});
        }
    }
    Timer {
        interval: 2200; running: true
        onTriggered: {
            var pass = weather.configuredLocation === "Tokyo" && weather.reportTempNum === "33" && paris.reportTempNum === "11" && tokyo.reportTempNum === "33" && paris.configuredLocation === "Paris" && tokyo.configuredLocation === "Tokyo";
            console.log(pass ? "WEATHER_CITY_SWITCH_PASSED" : "WEATHER_CITY_SWITCH_FAILED");
            Qt.quit();
        }
    }
}
