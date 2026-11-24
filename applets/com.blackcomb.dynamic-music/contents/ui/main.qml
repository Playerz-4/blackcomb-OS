/*
    Blackcomb Dynamic Music
    A compact MPRIS now-playing card for a dedicated top-right panel.
    No image assets are bundled: album art comes from the player and the
    fallback glyph is an icon-theme name.
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root

    readonly property string track: mprisModel.currentPlayer?.track ?? ""
    readonly property string artist: mprisModel.currentPlayer?.artist ?? ""
    readonly property string artUrl: mprisModel.currentPlayer?.artUrl ?? ""
    readonly property string identity: mprisModel.currentPlayer?.identity ?? ""
    readonly property int playbackStatus: mprisModel.currentPlayer?.playbackStatus ?? 0
    readonly property double length: mprisModel.currentPlayer?.length ?? 0
    readonly property double position: mprisModel.currentPlayer?.position ?? 0
    readonly property bool canControl: mprisModel.currentPlayer?.canControl ?? false
    readonly property bool canSeek: mprisModel.currentPlayer?.canSeek ?? false
    readonly property bool canGoNext: mprisModel.currentPlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: mprisModel.currentPlayer?.canGoPrevious ?? false
    readonly property bool isPlaying: root.playbackStatus === Mpris.PlaybackStatus.Playing

    width: Kirigami.Units.gridUnit * 18
    height: Kirigami.Units.gridUnit * 4

    Plasmoid.icon: switch (root.playbackStatus) {
    case Mpris.PlaybackStatus.Playing:
        return "media-playback-playing-symbolic";
    case Mpris.PlaybackStatus.Paused:
        return "media-playback-paused-symbolic";
    default:
        return "audio-x-generic";
    }
    Plasmoid.status: root.isPlaying ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    toolTipMainText: root.track.length > 0 ? root.track : i18n("No media playing")
    toolTipSubText: root.artist.length > 0 ? root.artist : root.identity

    Mpris.Mpris2Model {
        id: mprisModel
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: {
            if (mprisModel.currentPlayer) {
                mprisModel.currentPlayer.updatePosition();
            }
        }
    }

    function togglePlaying() {
        if (!mprisModel.currentPlayer) {
            return;
        }
        if (root.isPlaying) {
            mprisModel.currentPlayer.Pause();
        } else {
            mprisModel.currentPlayer.Play();
        }
    }

    function seekTo(value) {
        if (!mprisModel.currentPlayer || root.length <= 0) {
            return;
        }
        mprisModel.currentPlayer.position = Math.max(0, Math.min(root.length, value));
    }

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: Kirigami.Units.gridUnit * 4

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing / 2

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    id: compactArt
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: Kirigami.Units.iconSizes.large
                    radius: width / 2
                    color: Kirigami.Theme.backgroundColor
                    clip: true

                    Image {
                        id: compactImage
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artUrl.length > 0 && status === Image.Ready
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Math.round(parent.width * 0.7)
                        height: width
                        source: "audio-x-generic"
                        color: Kirigami.Theme.textColor
                        visible: !compactImage.visible
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: Kirigami.Theme.highlightColor
                        border.width: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.expanded = !root.expanded
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.track.length > 0 ? root.track : i18n("No media playing")
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.artist.length > 0 ? root.artist : root.identity
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        visible: text.length > 0
                    }
                }

                PlasmaComponents3.ToolButton {
                    visible: root.canControl
                    icon.name: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                    text: root.isPlaying ? i18n("Pause") : i18n("Play")
                    onClicked: root.togglePlaying()
                }
            }

            PlasmaComponents3.Slider {
                id: compactProgress
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
                from: 0
                to: Math.max(root.length, 1)
                value: root.position
                enabled: root.canSeek && root.length > 0
                onMoved: {
                    root.seekTo(value);
                    value = Qt.binding(function() { return root.position; });
                }
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 22
        implicitHeight: Kirigami.Units.gridUnit * 13

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Rectangle {
                    id: fullArt
                    Layout.preferredWidth: Kirigami.Units.iconSizes.enormous
                    Layout.preferredHeight: Kirigami.Units.iconSizes.enormous
                    radius: width / 2
                    color: Kirigami.Theme.backgroundColor
                    clip: true

                    Image {
                        id: fullImage
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artUrl.length > 0 && status === Image.Ready
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Math.round(parent.width * 0.6)
                        height: width
                        source: "audio-x-generic"
                        color: Kirigami.Theme.textColor
                        visible: !fullImage.visible
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.color: Kirigami.Theme.highlightColor
                        border.width: 1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        Layout.fillWidth: true
                        text: root.track.length > 0 ? root.track : i18n("No media playing")
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pixelSize: Kirigami.Units.gridUnit
                        wrapMode: Text.Wrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.artist.length > 0 ? root.artist : root.identity
                        color: Kirigami.Theme.disabledTextColor
                        wrapMode: Text.Wrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.identity
                        color: Kirigami.Theme.disabledTextColor
                        font.italic: true
                        visible: text.length > 0 && text !== root.artist
                        elide: Text.ElideRight
                    }
                }
            }

            PlasmaComponents3.Slider {
                id: fullProgress
                Layout.fillWidth: true
                from: 0
                to: Math.max(root.length, 1)
                value: root.position
                enabled: root.canSeek && root.length > 0
                onMoved: {
                    root.seekTo(value);
                    value = Qt.binding(function() { return root.position; });
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.ToolButton {
                    visible: root.canControl
                    enabled: root.canGoPrevious
                    icon.name: "media-skip-backward"
                    onClicked: mprisModel.currentPlayer.Previous()
                }

                PlasmaComponents3.ToolButton {
                    visible: root.canControl
                    icon.name: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                    text: root.isPlaying ? i18n("Pause") : i18n("Play")
                    onClicked: root.togglePlaying()
                }

                PlasmaComponents3.ToolButton {
                    visible: root.canControl
                    enabled: root.canGoNext
                    icon.name: "media-skip-forward"
                    onClicked: mprisModel.currentPlayer.Next()
                }
            }
        }
    }

    Component.onCompleted: {
        Plasmoid.removeInternalAction("configure");
    }
}
