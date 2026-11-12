pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../velunori.core/kit" as V

// The panel content. It reads `weather` (WeatherData, or a stand-in in tests)
// and calls its location functions; it fetches nothing itself.
Item {
    id: root
    property var weather: null
    property var theme: V.Theme {}
    // Condition icons are Nerd Font glyphs.
    property string iconFont: "monospace"
    signal closeRequested()

    readonly property bool editing: !!weather && weather.editingLocation
    readonly property bool saving: !!weather && weather.savingLocation
    readonly property var days: weather ? weather.forecastDays : []
    readonly property var suggestions: weather ? weather.locationSuggestions : []
    readonly property color hover: "#37363f"
    implicitHeight: column.implicitHeight

    function takeFocus() { if (editing) { search.forceActiveFocus(); search.selectAll(); } else keys.forceActiveFocus(); }
    Connections {
        target: root.weather
        function onEditingStarted() { search.text = root.weather.searchText; Qt.callLater(root.takeFocus); }
        function onEditingEnded() { Qt.callLater(root.takeFocus); }
    }

    Item {
        id: keys
        anchors.fill: parent; focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) { root.closeRequested(); event.accepted = true; }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.weather.startEditingLocation(); event.accepted = true; }
        }
    }

    ColumnLayout {
        id: column
        width: parent.width; spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Text { text: "VELUNORI"; color: root.theme.muted; font.pixelSize: 11; font.letterSpacing: 3; font.weight: Font.Medium }
            Item { Layout.fillWidth: true }
            Text { text: "Weather"; color: root.theme.muted; font.pixelSize: 12 }
            Text {
                objectName: "weatherClose"
                Layout.leftMargin: 10
                text: "✕"; color: closeArea.containsMouse ? root.theme.text : root.theme.muted; font.pixelSize: 13
                Accessible.name: "Close weather"
                MouseArea { id: closeArea; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
            }
        }

        // Current conditions.
        RowLayout {
            Layout.fillWidth: true; spacing: 16
            Text {
                objectName: "weatherIcon"
                textFormat: Text.PlainText
                text: root.weather && root.weather.label ? root.weather.label : "—"
                color: root.theme.accent; font.family: root.iconFont; font.pixelSize: 54
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                RowLayout {
                    spacing: 3
                    Text {
                        objectName: "weatherTemp"
                        textFormat: Text.PlainText
                        text: root.weather && root.weather.reportTempNum ? root.weather.reportTempNum : "—"
                        color: root.theme.text; font.pixelSize: 46; font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.alignment: Qt.AlignTop; Layout.topMargin: 9
                        text: root.weather && !root.weather.loading ? root.weather.tempUnit : ""
                        color: root.theme.muted; font.pixelSize: 18
                    }
                }
                Text {
                    objectName: "weatherCondition"
                    Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                    text: !root.weather || root.weather.loading ? "Fetching forecast…" : root.weather.condition
                    visible: text !== ""
                    color: root.theme.muted; font.pixelSize: 13
                }
            }
        }

        // Location: a chip that turns into a search field.
        Rectangle {
            objectName: "weatherLocation"
            visible: !root.editing
            Layout.fillWidth: true; implicitHeight: 38; radius: 12
            color: chipArea.containsMouse ? root.hover : root.theme.surface; border.color: root.theme.border
            Behavior on color { enabled: root.theme.motion; ColorAnimation { duration: 90 } }
            Accessible.name: "Change location"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                Text { text: ""; color: root.theme.accent; font.family: root.iconFont; font.pixelSize: 13 }
                Text {
                    Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                    text: root.weather && root.weather.reportLocation ? root.weather.reportLocation : "Detecting location…"
                    color: root.theme.text; font.pixelSize: 13
                }
                Text { text: "Change"; color: root.theme.muted; font.pixelSize: 12 }
            }
            MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.weather.startEditingLocation() }
        }
        RowLayout {
            visible: root.editing
            Layout.fillWidth: true; spacing: 8
            TextField {
                id: search
                objectName: "weatherSearch"
                Layout.fillWidth: true; implicitHeight: 38; leftPadding: 12; rightPadding: 12
                enabled: !root.saving
                placeholderText: "Search city"; placeholderTextColor: root.theme.muted; color: root.theme.text; font.pixelSize: 13
                Accessible.name: "Search city"
                background: Rectangle { radius: 12; color: root.theme.background; border.color: search.activeFocus ? root.theme.accent : root.theme.border }
                onTextEdited: root.weather.searchText = text
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) { root.weather.cancelEditingLocation(); event.accepted = true; }
                    else if (event.key === Qt.Key_Down) { if (root.weather.suggestionIndex < root.suggestions.length - 1) root.weather.suggestionIndex++; event.accepted = true; }
                    else if (event.key === Qt.Key_Up) { if (root.weather.suggestionIndex > 0) root.weather.suggestionIndex--; event.accepted = true; }
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.weather.searchText = text; root.weather.commitLocation(); event.accepted = true; }
                }
            }
            V.Button {
                objectName: "weatherAuto"
                implicitWidth: 92; implicitHeight: 38; accent: root.theme.accent
                enabled: !root.saving
                text: root.saving ? "Saving…" : "Automatic"
                Accessible.name: "Detect location automatically"
                onClicked: root.weather.clearLocation()
            }
        }
        ColumnLayout {
            visible: root.editing && !root.saving && root.suggestions.length > 0
            Layout.fillWidth: true; Layout.topMargin: -8; spacing: 2
            Repeater {
                model: root.suggestions
                Rectangle {
                    id: suggestion
                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.weather.suggestionIndex
                    objectName: "weatherSuggestion"
                    Layout.fillWidth: true; implicitHeight: 34; radius: 10
                    color: current ? root.theme.accent : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                        Text { text: suggestion.modelData.name; textFormat: Text.PlainText; color: suggestion.current ? root.theme.background : root.theme.text; font.pixelSize: 13; font.weight: Font.Medium }
                        Text {
                            Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                            text: suggestion.modelData.description
                            color: suggestion.current ? root.theme.background : root.theme.muted; opacity: suggestion.current ? 0.75 : 1; font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onPositionChanged: root.weather.suggestionIndex = suggestion.index
                        onClicked: root.weather.pickSuggestion(suggestion.modelData)
                    }
                }
            }
        }

        // Feels like, wind, humidity.
        RowLayout {
            visible: !!root.weather && !root.weather.loading
            Layout.fillWidth: true; spacing: 8
            Repeater {
                model: root.weather ? [["Feels like", root.weather.reportFeels], ["Wind", root.weather.reportWind], ["Humidity", root.weather.reportHumidity]] : []
                V.Surface {
                    id: stat
                    required property var modelData
                    objectName: "weatherStat"
                    Layout.fillWidth: true; Layout.preferredWidth: 100; implicitHeight: 62; radius: 14
                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 5
                        Text { text: stat.modelData[0]; color: root.theme.muted; font.pixelSize: 11 }
                        Text { text: stat.modelData[1]; textFormat: Text.PlainText; color: root.theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                    }
                }
            }
        }

        // Next days.
        ColumnLayout {
            visible: root.days.length > 0
            Layout.fillWidth: true; spacing: 8
            Text { text: "Next days"; color: root.theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Repeater {
                    model: root.days
                    V.Surface {
                        id: day
                        required property var modelData
                        objectName: "weatherDay"
                        Layout.fillWidth: true; Layout.preferredWidth: 100; implicitHeight: 96; radius: 14
                        Column {
                            anchors.centerIn: parent; spacing: 6
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weather.dayName(day.modelData.date); textFormat: Text.PlainText; color: root.theme.muted; font.pixelSize: 11 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weather.dayIcon(day.modelData); textFormat: Text.PlainText; color: root.theme.accent; font.family: root.iconFont; font.pixelSize: 24 }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                                Text { text: root.weather.bareTempForDay(day.modelData, "max"); color: root.theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { text: root.weather.bareTempForDay(day.modelData, "min"); color: root.theme.muted; font.pixelSize: 13 }
                            }
                        }
                    }
                }
            }
        }
    }
}
