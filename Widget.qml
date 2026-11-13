pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Ui
import "../velunori.core/kit" as V
import "components"
import "Model.js" as Model

Item {
    id: root
    property var bar: null
    property var settings: ({})
    property string moduleName: "velunori.weather"
    property bool opened: false
    // Hidden until the first forecast arrives, like the widget it replaces.
    readonly property bool wanted: forecast.label !== ""
    visible: wanted
    implicitWidth: wanted ? 34 : 0
    implicitHeight: bar ? bar.barSize : 40

    V.Theme { id: tokens; bar: root.bar }
    WeatherData { id: forecast; settings: root.settings }

    property int cityPoolRevision: 0
    readonly property var locations: {
        var cities = forecast.savedCities.slice();
        if (!cities.some(function(city) { return Model.wttrLocationQuery(city.name, city.latitude, city.longitude) === forecast.locationQuery; }))
            cities.unshift({id: "automatic", name: forecast.reportLocation || "Automatic location"});
        return cities;
    }
    readonly property var cityForecasts: {
        cityPoolRevision;
        var rows = [];
        for (var i = 0; i < cityPool.count; i++) { var item = cityPool.itemAt(i); if (item && item.source) rows.push({city: item.modelData, weather: item.source}); }
        return rows;
    }
    Repeater {
        id: cityPool; model: root.locations
        onItemAdded: root.cityPoolRevision++
        onItemRemoved: root.cityPoolRevision++
        Item {
            id: city
            required property var modelData
            readonly property bool primary: modelData.id === "automatic" || Model.wttrLocationQuery(modelData.name, modelData.latitude, modelData.longitude) === forecast.locationQuery
            readonly property var source: primary ? forecast : extra.item
            visible: false
            Loader { id: extra; active: !city.primary; sourceComponent: WeatherData { fixedLocation: city.modelData; active: root.opened; settings: root.settings } }
        }
    }
    function refreshCities() {
        forecast.refresh();
        for (var i = 0; i < cityPool.count; i++) { var item = cityPool.itemAt(i); if (item && item.source && item.source !== forecast) item.source.refresh(); }
    }

    function open() { opened = true; forecast.reload(); if (bar) bar.requestPopout(root); }
    function close() { if (forecast.editingLocation) forecast.cancelEditingLocation(); opened = false; if (bar) bar.releasePopout(root); }
    function closeForPopoutSwitch() { close(); }
    function toggle() { if (opened) close(); else open(); }

    WidgetButton {
        anchors.fill: parent; bar: root.bar; labelVisible: false; hasVisualContent: true; active: root.opened
        tooltipText: root.opened ? "" : [forecast.reportTempNum ? forecast.reportTempNum + forecast.tempUnit : "", forecast.condition, forecast.reportLocation].filter(function(part) { return !!part; }).join(" · ")
        onPressed: function(button) {
            if (button === Qt.RightButton) { if (root.bar) root.bar.run("omarchy-notification-send \"$(omarchy-weather-status)\""); }
            else if (button === Qt.MiddleButton) root.refreshCities();
            else root.toggle();
        }
        Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: forecast.label; color: tokens.accent
            font.family: Style.font.menuFamily; font.pixelSize: 15
        }
    }

    // Existing keybindings and `omarchy-shell omarchy.weather …` calls keep
    // working: this plugin stands in for the built-in weather widget.
    IpcHandler {
        target: "omarchy.weather"
        function open(): void { root.open() }
        function close(): void { root.close() }
        function show(): void { root.open() }
        function hide(): void { root.close() }
        function toggle(): void { root.toggle() }
        function edit(): void { root.open(); forecast.startEditingLocation() }
    }

    Loader { active: !!root.bar; sourceComponent: popup }
    Component {
        id: popup
        V.Panel {
            bar: root.bar; owner: root; anchorItem: root; open: root.opened
            centerOnIsland: true
            contentWidth: fittedContentWidth(420)
            contentHeight: fittedContentHeight(content.implicitHeight, screenH > 0 ? Math.floor(screenH * .8) : 560)
            focusTarget: content
            onOpenChanged: if (open) { content.resetOverview(); Qt.callLater(content.takeFocus); }
            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width; contentHeight: content.implicitHeight; clip: true
                boundsBehavior: Flickable.StopAtBounds
                WheelHandler {
                    target: null; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad; blocking: true
                    onWheel: function(event) {
                        var delta = event.pixelDelta.y ? event.pixelDelta.y * 3 : event.angleDelta.y / 120 * 180;
                        if (!delta) { event.accepted = false; return; }
                        flick.cancelFlick();
                        flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY - delta));
                        event.accepted = true;
                    }
                }
                ScrollBar.vertical: ScrollBar { policy: flick.contentHeight > flick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }
                WeatherContent {
                    id: content
                    width: flick.width - (flick.contentHeight > flick.height ? 10 : 0)
                    weather: forecast; cityForecasts: root.cityForecasts; theme: tokens; iconFont: Style.font.menuFamily
                    onCloseRequested: root.close()
                }
            }
        }
    }
}
