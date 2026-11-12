pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "../velunori.core/kit" as V
import "components"

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

    function open() { opened = true; forecast.reload(); if (bar) bar.requestPopout(root); }
    function close() { if (forecast.editingLocation) forecast.cancelEditingLocation(); opened = false; if (bar) bar.releasePopout(root); }
    function closeForPopoutSwitch() { close(); }
    function toggle() { if (opened) close(); else open(); }

    WidgetButton {
        anchors.fill: parent; bar: root.bar; labelVisible: false; hasVisualContent: true; active: root.opened
        tooltipText: root.opened ? "" : [forecast.reportTempNum ? forecast.reportTempNum + forecast.tempUnit : "", forecast.condition, forecast.reportLocation].filter(function(part) { return !!part; }).join(" · ")
        onPressed: function(button) {
            if (button === Qt.RightButton) { if (root.bar) root.bar.run("omarchy-notification-send \"$(omarchy-weather-status)\""); }
            else if (button === Qt.MiddleButton) forecast.refresh();
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
            contentWidth: fittedContentWidth(420)
            contentHeight: fittedContentHeight(content.implicitHeight, screenH > 0 ? Math.floor(screenH * .8) : 560)
            focusTarget: content
            onOpenChanged: if (open) Qt.callLater(content.takeFocus)
            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width; contentHeight: content.implicitHeight; clip: true
                boundsBehavior: Flickable.StopAtBounds
                WeatherContent {
                    id: content
                    width: flick.width
                    weather: forecast; theme: tokens; iconFont: Style.font.menuFamily
                    onCloseRequested: root.close()
                }
            }
        }
    }
}
