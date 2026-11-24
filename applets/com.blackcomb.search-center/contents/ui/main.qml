/*
    Blackcomb Search Center
    A centered pull-up panel with a search field, pinned applications,
    app/web suggestions from KRunner and the two most recent notifications.
    No image assets are bundled; all glyphs are icon-theme names.
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker
import org.kde.notificationmanager as NotificationManager

PlasmoidItem {
    id: root

    property Item searchField: null

    readonly property string query: root.searchField ? root.searchField.text.trim() : ""
    readonly property var resultModel: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null

    width: Kirigami.Units.iconSizes.large * 2
    height: Kirigami.Units.iconSizes.large * 2

    Plasmoid.icon: "search"
    Plasmoid.status: notificationModel.unreadNotificationsCount > 0
        ? PlasmaCore.Types.ActiveStatus
        : PlasmaCore.Types.PassiveStatus
    toolTipMainText: i18n("Search Center")
    toolTipSubText: notificationModel.unreadNotificationsCount > 0
        ? i18np("%1 unread notification", "%1 unread notifications", notificationModel.unreadNotificationsCount)
        : i18n("Search apps and the web")

    // RootModel owns KAStats favorites. Only the properties this panel needs
    // are set; the rest stay at their Plasma defaults.
    Kicker.RootModel {
        id: rootModel
        autoPopulate: false
        appletInterface: Plasmoid
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: true

        Component.onCompleted: {
            favoritesModel.initForClient("com.blackcomb.search-center.favorites.instance-" + Plasmoid.id);
        }
    }

    // Merged KRunner results cover installed applications and web-search
    // suggestions. The first merged row is what Kickoff itself displays.
    Kicker.RunnerModel {
        id: runnerModel
        query: root.query
        appletInterface: Plasmoid
        mergeResults: true
        favoritesModel: rootModel.favoritesModel

        onRequestUpdateQuery: requestedQuery => {
            if (root.searchField) {
                root.searchField.text = requestedQuery;
            }
        }
    }

    // limit: 2 is intentional: the concept calls for exactly two notification
    // rows. Grouping is disabled so those rows are individual notifications.
    NotificationManager.Notifications {
        id: notificationModel
        limit: 2
        showExpired: true
        showDismissed: false
        showJobs: false
        sortMode: NotificationManager.Notifications.SortByDate
        groupMode: NotificationManager.Notifications.GroupDisabled
        urgencies: NotificationManager.Notifications.LowUrgency
            | NotificationManager.Notifications.NormalUrgency
            | NotificationManager.Notifications.CriticalUrgency
    }

    function launchFavorite(row) {
        rootModel.favoritesModel.trigger(row, "", null);
        root.expanded = false;
    }

    function launchResult(row) {
        var results = runnerModel.modelForRow(0);
        if (results && row >= 0 && row < results.count) {
            results.trigger(row, "", null);
            root.expanded = false;
        }
    }

    function searchWeb() {
        if (root.query.length === 0) {
            return;
        }
        Qt.openUrlExternally("https://duckduckgo.com/?q=" + encodeURIComponent(root.query));
        root.expanded = false;
    }

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.large * 2
        implicitHeight: Kirigami.Units.iconSizes.large * 2

        PlasmaComponents3.ToolButton {
            anchors.centerIn: parent
            icon.name: "search"
            text: i18n("Search Center")
            onClicked: root.expanded = !root.expanded
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            width: Kirigami.Units.iconSizes.small
            height: width
            radius: width / 2
            color: Kirigami.Theme.highlightColor
            visible: notificationModel.unreadNotificationsCount > 0

            Text {
                anchors.centerIn: parent
                text: Math.min(99, notificationModel.unreadNotificationsCount)
                color: Kirigami.Theme.highlightedTextColor
                font.pixelSize: Math.max(7, parent.height - 4)
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 34
        implicitHeight: Kirigami.Units.gridUnit * 28

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: i18n("Search apps and the web…")
                Component.onCompleted: {
                    root.searchField = this;
                    forceActiveFocus();
                }
                Component.onDestruction: root.searchField = null
                Keys.onReturnPressed: {
                    if (root.resultModel && root.resultModel.count > 0) {
                        root.launchResult(0);
                    } else {
                        root.searchWeb();
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: i18n("Pinned apps")
                color: Kirigami.Theme.disabledTextColor
                font.bold: true
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge + Kirigami.Units.gridUnit
                orientation: ListView.Horizontal
                clip: true
                spacing: Kirigami.Units.smallSpacing
                model: rootModel.favoritesModel
                visible: rootModel.favoritesModel.count > 0

                delegate: Item {
                    required property int index

                    width: Kirigami.Units.gridUnit * 4
                    height: Kirigami.Units.iconSizes.huge + Kirigami.Units.gridUnit

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing / 2

                        Kirigami.Icon {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Kirigami.Units.iconSizes.large
                            Layout.preferredHeight: Kirigami.Units.iconSizes.large
                            source: model.decoration || "application-x-executable"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.display || ""
                            color: Kirigami.Theme.textColor
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: Kirigami.Units.smallSpacing * 2.5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.launchFavorite(index)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: i18n("No pinned apps yet. Pin one in the application launcher.")
                color: Kirigami.Theme.disabledTextColor
                wrapMode: Text.Wrap
                visible: rootModel.favoritesModel.count === 0
            }

            Text {
                Layout.fillWidth: true
                text: i18n("Search suggestions")
                color: Kirigami.Theme.disabledTextColor
                font.bold: true
                visible: root.query.length > 0
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Kirigami.Units.smallSpacing
                model: root.resultModel
                visible: root.query.length > 0 && root.resultModel && root.resultModel.count > 0

                delegate: Item {
                    required property int index

                    width: ListView.view.width
                    height: Kirigami.Units.gridUnit * 2

                    RowLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            source: model.decoration || "application-x-executable"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: model.display || ""
                                color: Kirigami.Theme.textColor
                                elide: Text.ElideRight
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.description || ""
                                color: Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.launchResult(index)
                    }
                }
            }

            PlasmaComponents3.ToolButton {
                Layout.fillWidth: true
                icon.name: "internet-web-browser"
                text: i18n("Search the web for “%1”", root.query)
                visible: root.query.length > 0
                onClicked: root.searchWeb()
            }

            Text {
                Layout.fillWidth: true
                text: i18n("Notifications")
                color: Kirigami.Theme.disabledTextColor
                font.bold: true
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 9
                clip: true
                spacing: Kirigami.Units.smallSpacing
                model: notificationModel

                delegate: Item {
                    required property int index

                    width: ListView.view.width
                    height: Kirigami.Units.gridUnit * 4

                    Rectangle {
                        anchors.fill: parent
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.disabledTextColor
                        border.width: 1
                        radius: Kirigami.Units.smallSpacing
                    }

                    // Behind the content: lets the whole row invoke the
                    // default action without stealing the close button.
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (model.hasDefaultAction) {
                                notificationModel.invokeDefaultAction(
                                    notificationModel.index(index, 0),
                                    NotificationManager.Notifications.Close);
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            source: model.applicationIconName || model.iconName || "dialog-information"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: model.applicationName || ""
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: Kirigami.Units.smallSpacing * 2.5
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.summary || ""
                                color: Kirigami.Theme.textColor
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.body || ""
                                color: Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }

                        PlasmaComponents3.ToolButton {
                            visible: model.closable
                            icon.name: "window-close"
                            onClicked: notificationModel.close(index)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: i18n("No notifications")
                color: Kirigami.Theme.disabledTextColor
                visible: notificationModel.count === 0
            }
        }
    }

    Component.onCompleted: {
        Plasmoid.removeInternalAction("configure");
    }
}
