pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../lib/kit" as V

// The panel content. It reads `weather` (WeatherData, or a stand-in in tests)
// and calls its location functions; it fetches nothing itself.
Item {
    id: root
    property var weather: null
    property var theme: V.Theme {}
    // Condition icons are Nerd Font glyphs.
    property string iconFont: "monospace"
    property bool citiesOpen: false
    property var cityForecasts: []
    property string detailCityId: ""
    readonly property bool showOverview: cityForecasts.length > 1 && !detailCityId && !editing
    readonly property var displayWeather: {
        var row = cityForecasts.find(function(row) { return row.city.id === root.detailCityId; });
        return row ? row.weather : weather;
    }
    function resetOverview() { detailCityId = ""; citiesOpen = false; }
    onCityForecastsChanged: if (detailCityId && !cityForecasts.some(function(row) { return row.city.id === root.detailCityId; })) detailCityId = ""
    signal closeRequested()

    readonly property bool editing: !!weather && weather.editingLocation
    readonly property bool saving: !!weather && weather.savingLocation
    readonly property var days: displayWeather ? displayWeather.forecastDays : []
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
        V.Button { objectName: "weatherAllCities"; visible: !!root.detailCityId && root.cityForecasts.length > 1; text: "‹ All cities"; implicitHeight: 30; accent: root.theme.accent; onClicked: root.detailCityId = "" }
        ColumnLayout {
            visible: root.showOverview
            Layout.fillWidth: true; spacing: 10
            Text { text: "Your cities"; color: root.theme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
            Text { text: "Current weather · select a city for its weekly forecast"; color: root.theme.muted; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Repeater {
                model: root.cityForecasts
                AbstractButton {
                    id: cityCard
                    required property var modelData
                    objectName: "weatherCityCard"
                    Layout.fillWidth: true; implicitHeight: 86; hoverEnabled: true
                    Accessible.name: modelData.city.name + ", " + modelData.weather.reportTempNum + modelData.weather.tempUnit
                    onClicked: root.detailCityId = modelData.city.id
                    background: Rectangle { radius: 14; color: cityCard.hovered ? root.hover : root.theme.surface; border.color: cityCard.activeFocus ? root.theme.accent : root.theme.border }
                    contentItem: RowLayout {
                        spacing: 12
                        Text { Layout.leftMargin: 14; text: cityCard.modelData.weather.label; color: root.theme.accent; font.family: root.iconFont; font.pixelSize: 27; Layout.preferredWidth: 36 }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            Text { text: cityCard.modelData.city.name; textFormat: Text.PlainText; color: root.theme.text; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: cityCard.modelData.weather.loading ? "Fetching forecast…" : cityCard.modelData.weather.condition; textFormat: Text.PlainText; color: root.theme.muted; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        Text { Layout.rightMargin: 14; text: cityCard.modelData.weather.loading ? "—" : cityCard.modelData.weather.reportTempNum + cityCard.modelData.weather.tempUnit; color: root.theme.text; font.pixelSize: 26; font.weight: Font.Medium }
                    }
                }
            }
        }
        RowLayout {
            visible: !root.showOverview
            Layout.fillWidth: true; spacing: 16
            Text {
                objectName: "weatherIcon"
                textFormat: Text.PlainText
                text: root.displayWeather && root.displayWeather.label ? root.displayWeather.label : "—"
                color: root.theme.accent; font.family: root.iconFont; font.pixelSize: 54
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                RowLayout {
                    spacing: 3
                    Text {
                        objectName: "weatherTemp"
                        textFormat: Text.PlainText
                        text: root.displayWeather && root.displayWeather.reportTempNum ? root.displayWeather.reportTempNum : "—"
                        color: root.theme.text; font.pixelSize: 46; font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.alignment: Qt.AlignTop; Layout.topMargin: 9
                        text: root.displayWeather && !root.displayWeather.loading ? root.displayWeather.tempUnit : ""
                        color: root.theme.muted; font.pixelSize: 18
                    }
                }
                Text {
                    objectName: "weatherCondition"
                    Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                    text: !root.displayWeather || root.displayWeather.loading ? "Fetching forecast…" : root.displayWeather.condition
                    visible: text !== ""
                    color: root.theme.muted; font.pixelSize: 13
                }
            }
        }

        // Location: a chip that turns into a search field.
        Rectangle {
            id: locationChip
            objectName: "weatherLocation"
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Keys.onReturnPressed: root.citiesOpen = !root.citiesOpen
            Keys.onSpacePressed: root.citiesOpen = !root.citiesOpen
            visible: !root.editing
            Layout.fillWidth: true; implicitHeight: 38; radius: 12
            color: chipArea.containsMouse ? root.hover : root.theme.surface; border.color: locationChip.activeFocus ? root.theme.accent : root.theme.border
            Behavior on color { enabled: root.theme.motion; ColorAnimation { duration: 90 } }
            Accessible.name: "Choose or manage weather cities"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                Text { text: ""; color: root.theme.accent; font.family: root.iconFont; font.pixelSize: 13 }
                Text {
                    Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                    text: root.showOverview ? "Manage saved cities" : root.displayWeather && root.displayWeather.reportLocation ? root.displayWeather.reportLocation : "Detecting location…"
                    color: root.theme.text; font.pixelSize: 13
                }
                Text { text: "Cities"; color: root.theme.muted; font.pixelSize: 12 }
            }
            MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.citiesOpen = !root.citiesOpen }
        }
        Text { visible: root.weather && !!root.weather.cityError; text: root.weather ? root.weather.cityError || "" : ""; color: "#eaa7bb"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
        ColumnLayout {
            visible: root.citiesOpen && !root.editing
            Layout.fillWidth: true; spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Saved cities"; color: root.theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                V.Button { objectName: "weatherAddCity"; text: "+ Add city"; implicitHeight: 30; implicitWidth: 94; accent: root.theme.accent; onClicked: { root.citiesOpen = false; root.weather.startEditingLocation(); } }
            }
            Repeater {
                model: root.weather ? root.weather.savedCities || [] : []
                RowLayout {
                    id: cityRow
                    required property var modelData
                    objectName: "weatherSavedCity"
                    Layout.fillWidth: true; spacing: 6
                    V.Button {
                        id: cityButton
                        objectName: "weatherSelectCity"
                        implicitWidth: 100; Layout.minimumWidth: 0
                        contentItem: Text { text: cityButton.text; textFormat: Text.PlainText; color: cityButton.primary ? root.theme.background : root.theme.text; font.pixelSize: 13; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                        Layout.fillWidth: true; implicitHeight: 34; accent: root.theme.accent
                        text: cityRow.modelData.name + (cityRow.modelData.description ? " · " + cityRow.modelData.description : "")
                        primary: root.weather.isSelectedCity(cityRow.modelData)
                        enabled: !root.saving
                        onClicked: { root.weather.selectCity(cityRow.modelData); root.citiesOpen = false; }
                    }
                    V.Button { objectName: "weatherRemoveCity"; text: "×"; implicitWidth: 32; implicitHeight: 32; accent: root.theme.accent; enabled: !root.saving; Accessible.name: "Remove city: " + cityRow.modelData.name; onClicked: root.weather.removeCity(cityRow.modelData) }
                }
            }
            V.Button { text: "Automatic location"; implicitHeight: 32; accent: root.theme.accent; enabled: !root.saving; onClicked: { root.weather.clearLocation(); root.citiesOpen = false; } }
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
            visible: !root.showOverview && !!root.displayWeather && !root.displayWeather.loading
            Layout.fillWidth: true; spacing: 8
            Repeater {
                model: root.displayWeather ? [["Feels like", root.displayWeather.reportFeels], ["Wind", root.displayWeather.reportWind], ["Humidity", root.displayWeather.reportHumidity]] : []
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

        // A compact weekly agenda keeps all seven days legible at panel width.
        ColumnLayout {
            visible: !root.showOverview && root.days.length > 0
            Layout.fillWidth: true; spacing: 4
            RowLayout {
                Layout.fillWidth: true; Layout.bottomMargin: 4
                Text { text: root.days.length >= 7 ? "Next 7 days" : "Upcoming forecast"; color: root.theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                Text { text: "Low / High"; color: root.theme.muted; font.pixelSize: 11 }
            }
            Repeater {
                model: root.days
                Item {
                    id: day
                    required property var modelData
                    objectName: "weatherDay"
                    Layout.fillWidth: true; implicitHeight: 32
                    RowLayout {
                        anchors.fill: parent; spacing: 10
                        Text { Layout.fillWidth: true; text: root.displayWeather.dayName(day.modelData.date); textFormat: Text.PlainText; color: root.theme.text; font.pixelSize: 12; elide: Text.ElideRight }
                        Text { text: Qt.formatDate(new Date(day.modelData.date + "T12:00:00"), "d MMM"); color: root.theme.muted; font.pixelSize: 11; Layout.preferredWidth: 48 }
                        Text { text: root.displayWeather.dayIcon(day.modelData); textFormat: Text.PlainText; color: root.theme.accent; font.family: root.iconFont; font.pixelSize: 22; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignHCenter }
                        Text { text: root.displayWeather.bareTempForDay(day.modelData, "min"); color: root.theme.muted; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                        Text { text: root.displayWeather.bareTempForDay(day.modelData, "max"); color: root.theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }
    }
}
