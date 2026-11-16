//@ pragma OmarchyLoadPatch
import QtQuick
import Quickshell
import qs.Commons
import "velunori.weather/components"
import "velunori.weather" as W
import "velunori.weather/Model.js" as Model
import "velunori.weather/Conditions.js" as Conditions
import "lib/kit" as V
import "lib/kit/PanelGeometry.js" as PanelGeometry

ShellRoot {
    id: testRoot
    property string failure: ""
    property bool rpcDone: false
    property bool uiDone: false
    function finish() { if (uiDone && rpcDone) { console.log(failure ? "WEATHER_TEST_FAILED " + failure : "WEATHER_TEST_PASSED"); Qt.quit(); } }
    W.CityStore {
        id: store
        onCompleted: function(request, ok) {
            check(ok, "city store RPC " + request.action);
            if (request.action === "add") { check(cities.some(function(city) { return city.name === "Fixture"; }), "saved city returned through RPC"); perform({action: "remove", id: cities.find(function(city) { return city.name === "Fixture"; }).id}); }
            if (request.action === "remove") { check(!cities.some(function(city) { return city.name === "Fixture"; }), "city removal returned through RPC"); testRoot.rpcDone = true; testRoot.finish(); }
        }
    }
    Timer { interval: 80; running: true; onTriggered: store.perform({action:"add",city:{name:"Fixture",latitude:1,longitude:2}}) }
    Timer { interval: 6000; running: true; onTriggered: { console.log("WEATHER_TEST_FAILED city RPC timed out"); Qt.quit(); } }
    function check(value, message) { if (!value) failure += message + "; "; }
    function find(parent, name) { if (parent.objectName === name) return parent; var kids = parent.children || []; for (var i = 0; i < kids.length; i++) { var hit = find(kids[i], name); if (hit) return hit; } return null; }
    function findAll(parent, name, out) { out = out || []; if (parent.objectName === name && parent.visible) out.push(parent); var kids = parent.children || []; for (var i = 0; i < kids.length; i++) findAll(kids[i], name, out); return out; }
    Item {
        id: island
        property bool velunoriPanelAnchor: true
        width: 600
        Item {
            id: capsule
            property bool velunoriPanelAnchor: true
            width: 280
            Item { id: widget; x: 230; width: 34 }
        }
    }
    readonly property var popupAnchor: PanelGeometry.islandAnchor(widget)
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
        property string configuredLocation: "Kraków"
        property string cityError: ""
        property var savedCities: [{id:"krakow",name:"Kraków",latitude:50.06,longitude:19.94},{id:"berlin",name:"Berlin",latitude:52.52,longitude:13.4}]
        property var selected: null
        property var removed: null
        function isSelectedCity(city) { return city.name === configuredLocation; }
        function selectCity(city) { selected = city; }
        function removeCity(city) { removed = city; }
        property var forecastDays: [
            {date: "2026-11-13", maxtempC: "11", mintempC: "5", openMeteoWeatherCode: 61},
            {date: "2026-11-14", maxtempC: "9", mintempC: "3", openMeteoWeatherCode: 3},
            {date: "2026-11-15", maxtempC: "7", mintempC: "0", openMeteoWeatherCode: 71},
            {date: "2026-11-16", maxtempC: "8", mintempC: "1", openMeteoWeatherCode: 3},
            {date: "2026-11-17", maxtempC: "10", mintempC: "2", openMeteoWeatherCode: 2},
            {date: "2026-11-18", maxtempC: "11", mintempC: "3", openMeteoWeatherCode: 0},
            {date: "2026-11-19", maxtempC: "9", mintempC: "2", openMeteoWeatherCode: 61}]
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
    Item {
        id: berlin
        property string label: fake.label
        property bool loading: false
        property string reportTempNum: "8"
        property string tempUnit: "°C"
        property string condition: "Partly cloudy"
    }
    V.Theme { id: tokens; bar: ({velunori: {apiVersion: 1, accentName: "lavender", motion: true}}) }
    FloatingWindow {
        visible: true; implicitWidth: 420; implicitHeight: Quickshell.env("VELUNORI_PREVIEW_HEIGHT") ? Number(Quickshell.env("VELUNORI_PREVIEW_HEIGHT")) : Math.min(640, view.implicitHeight + 40); color: "transparent"
        Rectangle {
            id: surface
            anchors.fill: parent; radius: 18; color: "#202026"; border.color: "#48464f"
            Flickable {
                id: viewport
                anchors.fill: parent; anchors.margins: 20
                contentWidth: width; contentHeight: view.implicitHeight; clip: true
                boundsBehavior: Flickable.StopAtBounds
                WeatherContent { id: view; width: viewport.width; weather: fake; theme: tokens; iconFont: Style.font.menuFamily }
            }
        }
    }
    property int closes: 0
    Connections { target: view; function onCloseRequested() { testRoot.closes++; } }
    Timer {
        interval: 300; running: true
        onTriggered: {
            check(popupAnchor === capsule, "Orbit chooses capsule instead of weather icon");
            capsule.velunoriPanelAnchor = false;
            check(popupAnchor === island, "switching to Island chooses its whole surface");
            island.velunoriPanelAnchor = false;
            check(popupAnchor === widget, "other bars retain their widget anchor");
            var preview = Quickshell.env("VELUNORI_PREVIEW_PATH");
            if (preview) {
                if (!Quickshell.env("VELUNORI_PREVIEW_STATE")) view.cityForecasts = [{city:{id:"krakow",name:"Kraków"},weather:fake},{city:{id:"berlin",name:"Berlin"},weather:berlin}];
                if (Quickshell.env("VELUNORI_PREVIEW_STATE") === "cities") view.citiesOpen = true;
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
            check(findAll(view, "weatherStat").length === 3 && findAll(view, "weatherDay").length === 7, "three figures and seven forecast days");
            var weeklyRows = findAll(view, "weatherDay");
            viewport.contentY = Math.max(0, viewport.contentHeight - viewport.height);
            var last = weeklyRows[weeklyRows.length - 1];
            var lastPoint = last.mapToItem(viewport, 0, 0);
            check(lastPoint.y >= -1 && lastPoint.y + last.height <= viewport.height + 1, "last forecast day is reachable in a short panel");
            viewport.contentY = 0;
            view.cityForecasts = [{city:{id:"a",name:"Kraków"},weather:fake},{city:{id:"b",name:"Berlin"},weather:fake}];
            check(view.showOverview && findAll(view,"weatherCityCard").length === 2, "all saved cities show simultaneously by default");
            findAll(view,"weatherCityCard")[1].clicked();
            check(!view.showOverview && view.detailCityId === "b", "city card opens its weekly detail");
            find(view,"weatherAllCities").clicked();
            check(view.showOverview && !fake.selected, "details do not change the primary city");
            view.cityForecasts = [];
            view.citiesOpen = true;
            check(findAll(view,"weatherSavedCity").length === 2, "saved cities appear in the manager");
            findAll(view,"weatherSelectCity")[1].clicked();
            check(fake.selected.name === "Berlin" && !view.citiesOpen, "choosing a saved city switches and closes manager");
            view.citiesOpen = true;
            findAll(view,"weatherRemoveCity")[1].clicked();
            check(fake.removed.id === "berlin", "remove targets one saved city");
            find(view,"weatherAddCity").clicked();
            check(fake.editingLocation && !view.citiesOpen, "adding a city opens geocoding");
            fake.cancelEditingLocation();
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
            uiDone = true; finish();
        }
    }
    Timer {
        id: grab
        interval: 500
        onTriggered: surface.grabToImage(function(result) {
            console.log(failure ? "WEATHER_TEST_FAILED " + failure : result.saveToFile(Quickshell.env("VELUNORI_PREVIEW_PATH")) ? "WEATHER_PREVIEW_SAVED" : "WEATHER_PREVIEW_FAILED");
            Qt.quit();
        })
    }
}
