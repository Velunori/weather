pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
Item {
    id: root
    visible: false
    property bool active: true
    property var cities: []
    property var queue: []
    property bool completing: false
    property string error: ""
    signal completed(var request, bool ok)
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("cities.py").toString().replace(/^(file|qs):\/\//, ""))
    function acceptCities(value) { if (JSON.stringify(cities) !== JSON.stringify(value)) cities = value; }
    function perform(request) { if (!active) return; queue = queue.concat([request]); drain(); }
    function drain() { if (completing || process.running || !queue.length) return; process.request = queue[0]; queue = queue.slice(1); process.running = true; }
    Component.onCompleted: if (active) perform({action: "list"})
    FileView {
        id: file
        path: !root.active ? "" : (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/velunori/weather/cities.json"
        watchChanges: root.active; printErrors: false
        onFileChanged: reload()
        onLoaded: { if (process.running || root.queue.length) return; try { root.acceptCities(JSON.parse(text()).cities || []); } catch (e) {} }
    }
    Timer { interval: 15000; running: root.active; repeat: true; onTriggered: file.reload() }
    Process {
        id: process
        property var request: ({})
        property string result: ""
        command: ["python3", root.helper]; stdinEnabled: true
        onStarted: { result = ""; write(JSON.stringify(request) + "\n"); }
        stdout: StdioCollector { onStreamFinished: process.result = text; }
        onExited: {
            root.completing = true;
            try { var reply = JSON.parse(result); if (!reply.ok) throw new Error(); root.acceptCities(reply.cities); root.error = ""; }
            catch(e) { root.error = "Could not load or save cities."; }
            root.completed(request, root.error === ""); request = ({}); root.completing = false;
            file.reload(); Qt.callLater(root.drain);
        }
    }
}
