//@ pragma OmarchyLoadPatch
import QtQuick
import Quickshell
import qs.Commons
import "velunori.weather/components"
import "velunori.weather/Model.js" as Model
import "velunori.weather/Conditions.js" as Conditions
import "velunori.core/kit" as V

ShellRoot {
    id: testRoot
    property string failure: ""
    function check(value, message) { if (!value) failure += message + "; "; }
    function find(parent, name) { if (parent.objectName === name) return parent; var kids = parent.children || []; for (var i = 0; i < kids.length; i++) { var hit = find(kids[i], name); if (hit) return hit; } return null; }
    function findAll(parent, name, out) { out = out || []; if (parent.objectName === name && parent.visible) out.push(parent); var kids = parent.children || []; for (var i = 0; i < kids.length; i++) findAll(kids[i], name, out); return out; }
    Item {
        id: fake
        signal editingStarted()
        signal editingEnded()
        property var current: ({openMeteoWeatherCode: 2, isDay: 1})
        property bool loading: false
        property string label: Model.currentIcon(current, "")
        property string condition: Conditions.describe(current)
        property string reportTempNum: "12"
        property string tempUnit: "°C"
        property string reportFeels: "10°C"
        property string reportWind: "14 km/h"
        property string reportHumidity: "71%"
        property string reportLocation: "Kraków"
        property var forecastDays: [
            {date: "2026-11-13", maxtempC: "11", mintempC: "5", openMeteoWeatherCode: 61},
            {date: "2026-11-14", maxtempC: "9", mintempC: "3", openMeteoWeatherCode: 3},
            {date: "2026-11-15", maxtempC: "7", mintempC: "0", openMeteoWeatherCode: 71}]
        property bool editingLocation: false
        property bool savingLocation: false
        property var locationSuggestions: []
        property int suggestionIndex: 0
        property string searchText: ""
        property var picked: null
        property int commits: 0
        property int clears: 0
        function dayName(date) { return Model.dayName(date, function(value) { return Qt.formatDate(value, "dddd"); }); }
        function dayIcon(day) { return Model.dayIcon(day); }
        function bareTempForDay(day, kind) { return Model.bareTempForDay(day, kind, false); }
        function startEditingLocation() { editingLocation = true; searchText = reportLocation; editingStarted(); }
        function cancelEditingLocation() { editingLocation = false; locationSuggestions = []; editingEnded(); }
        function commitLocation() { commits++; }
        function clearLocation() { clears++; cancelEditingLocation(); }
        function pickSuggestion(row) { picked = row; }
    }
    V.Theme { id: tokens; bar: ({velunori: {apiVersion: 1, accentName: "lavender", motion: true}}) }
    FloatingWindow {
        visible: true; implicitWidth: 460; implicitHeight: view.implicitHeight + 40; color: "transparent"
        Rectangle {
            id: surface
            anchors.fill: parent; radius: 18; color: "#202026"; border.color: "#48464f"
            WeatherContent { id: view; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20; weather: fake; theme: tokens; iconFont: Style.font.menuFamily }
        }
    }
    property int closes: 0
    Connections { target: view; function onCloseRequested() { testRoot.closes++; } }
    Timer {
        interval: 300; running: true
        onTriggered: {
            var preview = Quickshell.env("VELUNORI_PREVIEW_PATH");
            if (preview) {
                if (Quickshell.env("VELUNORI_PREVIEW_STATE") === "search") {
                    fake.startEditingLocation();
                    fake.locationSuggestions = [{name: "Gdańsk", description: "Pomerania, Poland"}, {name: "Gdynia", description: "Pomerania, Poland"}, {name: "Gdów", description: "Lesser Poland, Poland"}];
                    find(view, "weatherSearch").text = "Gd";
                }
                grab.start();
                return;
            }
            check(find(view, "weatherTemp").text === "12" && find(view, "weatherCondition").text === "Partly cloudy", "current temperature and condition");
            check(find(view, "weatherIcon").text === fake.label && fake.label !== "", "condition icon comes from the shared model");
            check(findAll(view, "weatherStat").length === 3 && findAll(view, "weatherDay").length === 3, "three figures and three forecast days");
            var chip = find(view, "weatherLocation"), search = find(view, "weatherSearch");
            check(chip.visible && !search.visible, "location is a chip until edited");
            fake.startEditingLocation();
            check(!chip.visible && search.visible && search.text === "Kraków", "editing swaps in a search field holding the current place");
            search.text = "Gd"; search.textEdited();
            check(fake.searchText === "Gd", "typed text reaches the data layer for geocoding");
            fake.locationSuggestions = [{name: "Gdańsk", description: "Pomerania, Poland", latitude: 54.35, longitude: 18.65}, {name: "Gdynia", description: "Pomerania, Poland", latitude: 54.52, longitude: 18.53}];
            var rows = findAll(view, "weatherSuggestion");
            check(rows.length === 2 && rows[0].current && !rows[1].current, "suggestions list with the first one selected");
            fake.suggestionIndex = 1; check(rows[1].current, "selection follows the index");
            find(view, "weatherAuto").clicked();
            check(fake.clears === 1 && !fake.editingLocation && chip.visible, "Automatic clears the stored location and leaves editing");
            fake.current = null; fake.loading = true; fake.reportTempNum = "";
            check(find(view, "weatherCondition").text === "Fetching forecast…" && findAll(view, "weatherStat").length === 0 && find(view, "weatherTemp").text === "—", "loading state shows no stale figures");
            find(view, "weatherClose").children[0].clicked(null);
            check(testRoot.closes === 1, "close button asks the host to close");
            console.log(failure === "" ? "WEATHER_TEST_PASSED" : "WEATHER_TEST_FAILED " + failure);
            Qt.quit();
        }
    }
    Timer {
        id: grab
        interval: 500
        onTriggered: surface.grabToImage(function(result) {
            console.log(result.saveToFile(Quickshell.env("VELUNORI_PREVIEW_PATH")) ? "WEATHER_PREVIEW_SAVED" : "WEATHER_PREVIEW_FAILED");
            Qt.quit();
        })
    }
}
