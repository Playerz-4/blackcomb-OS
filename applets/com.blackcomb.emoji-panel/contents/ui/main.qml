/*
    Blackcomb Emoji & Clipboard
    A plain-QML panel opened with Meta+. from anywhere in Plasma. It offers
    Google Noto style emoji, ASCII art/kaomoji, common symbols and a clipboard
    with a session history. Copying an item places it on the system clipboard;
    no SVG artwork, helper binary or new QML module dependency is used.
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property int tab: 0
    property string group: "All"
    property string emojiFilter: ""
    property string copiedText: ""
    property string currentClipboard: ""

    width: Kirigami.Units.iconSizes.large * 2
    height: Kirigami.Units.iconSizes.large * 2

    Plasmoid.icon: "face-smile"
    toolTipMainText: i18n("Emoji & Clipboard")
    toolTipSubText: i18n("Meta+. — emoji, ASCII art, symbols and clipboard")

    // Google's Noto Color Emoji names are used as the search keywords; the
    // glyphs themselves are rendered by Qt's normal font fallback.
    readonly property var allEmojis: [
        { group: "Faces", glyph: "😀", name: "grinning face" },
        { group: "Faces", glyph: "😃", name: "smiling face with open mouth" },
        { group: "Faces", glyph: "😄", name: "smiling face with smiling eyes" },
        { group: "Faces", glyph: "😁", name: "beaming face" },
        { group: "Faces", glyph: "😆", name: "grinning squinting face" },
        { group: "Faces", glyph: "😅", name: "grinning face with sweat" },
        { group: "Faces", glyph: "😂", name: "face with tears of joy" },
        { group: "Faces", glyph: "🙂", name: "slightly smiling face" },
        { group: "Faces", glyph: "🙃", name: "upside-down face" },
        { group: "Faces", glyph: "😉", name: "winking face" },
        { group: "Faces", glyph: "😊", name: "smiling face with smiling eyes" },
        { group: "Faces", glyph: "😇", name: "smiling face with halo" },
        { group: "Faces", glyph: "🥰", name: "smiling face with hearts" },
        { group: "Faces", glyph: "😍", name: "smiling face with heart-eyes" },
        { group: "Faces", glyph: "😘", name: "face blowing a kiss" },
        { group: "Faces", glyph: "😋", name: "face savoring food" },
        { group: "Faces", glyph: "😜", name: "winking face with tongue" },
        { group: "Faces", glyph: "🤪", name: "zany face" },
        { group: "Faces", glyph: "🤨", name: "face with raised eyebrow" },
        { group: "Faces", glyph: "🧐", name: "face with monocle" },
        { group: "Faces", glyph: "🤓", name: "nerd face" },
        { group: "Faces", glyph: "😎", name: "smiling face with sunglasses" },
        { group: "Faces", glyph: "🥳", name: "partying face" },
        { group: "Faces", glyph: "😏", name: "smirking face" },
        { group: "Faces", glyph: "😒", name: "unamused face" },
        { group: "Faces", glyph: "😞", name: "disappointed face" },
        { group: "Faces", glyph: "😔", name: "pensive face" },
        { group: "Faces", glyph: "😢", name: "crying face" },
        { group: "Faces", glyph: "😭", name: "loudly crying face" },
        { group: "Faces", glyph: "😤", name: "face with steam from nose" },
        { group: "Faces", glyph: "😡", name: "enraged face" },
        { group: "Faces", glyph: "🤯", name: "exploding head" },
        { group: "Faces", glyph: "😱", name: "face screaming in fear" },
        { group: "Faces", glyph: "🥺", name: "pleading face" },
        { group: "Faces", glyph: "😴", name: "sleeping face" },
        { group: "Faces", glyph: "🤔", name: "thinking face" },
        { group: "Faces", glyph: "🤗", name: "smiling face with open hands" },
        { group: "Faces", glyph: "🤭", name: "face with hand over mouth" },
        { group: "Faces", glyph: "😶", name: "face without mouth" },
        { group: "Faces", glyph: "😐", name: "neutral face" },
        { group: "Hands", glyph: "👍", name: "thumbs up" },
        { group: "Hands", glyph: "👎", name: "thumbs down" },
        { group: "Hands", glyph: "👌", name: "OK hand" },
        { group: "Hands", glyph: "🤌", name: "pinched fingers" },
        { group: "Hands", glyph: "✌", name: "victory hand" },
        { group: "Hands", glyph: "🤞", name: "crossed fingers" },
        { group: "Hands", glyph: "🤟", name: "love-you gesture" },
        { group: "Hands", glyph: "🤘", name: "sign of the horns" },
        { group: "Hands", glyph: "👏", name: "clapping hands" },
        { group: "Hands", glyph: "🙌", name: "raising hands" },
        { group: "Hands", glyph: "🤝", name: "handshake" },
        { group: "Hands", glyph: "🙏", name: "folded hands" },
        { group: "Hands", glyph: "💪", name: "flexed biceps" },
        { group: "Hands", glyph: "👋", name: "waving hand" },
        { group: "Nature", glyph: "🐶", name: "dog face" },
        { group: "Nature", glyph: "🐱", name: "cat face" },
        { group: "Nature", glyph: "🦊", name: "fox face" },
        { group: "Nature", glyph: "🐻", name: "bear face" },
        { group: "Nature", glyph: "🐼", name: "panda face" },
        { group: "Nature", glyph: "🦁", name: "lion face" },
        { group: "Nature", glyph: "🐮", name: "cow face" },
        { group: "Nature", glyph: "🐷", name: "pig face" },
        { group: "Nature", glyph: "🐸", name: "frog face" },
        { group: "Nature", glyph: "🐵", name: "monkey face" },
        { group: "Nature", glyph: "🌻", name: "sunflower" },
        { group: "Nature", glyph: "🌈", name: "rainbow" },
        { group: "Nature", glyph: "🌙", name: "crescent moon" },
        { group: "Nature", glyph: "⭐", name: "star" },
        { group: "Nature", glyph: "🔥", name: "fire" },
        { group: "Food", glyph: "🍎", name: "red apple" },
        { group: "Food", glyph: "🍊", name: "tangerine" },
        { group: "Food", glyph: "🍋", name: "lemon" },
        { group: "Food", glyph: "🍉", name: "watermelon" },
        { group: "Food", glyph: "🍓", name: "strawberry" },
        { group: "Food", glyph: "🍒", name: "cherries" },
        { group: "Food", glyph: "🥑", name: "avocado" },
        { group: "Food", glyph: "🍕", name: "pizza" },
        { group: "Food", glyph: "🍔", name: "hamburger" },
        { group: "Food", glyph: "🌮", name: "taco" },
        { group: "Food", glyph: "🍜", name: "steaming bowl" },
        { group: "Food", glyph: "🍩", name: "doughnut" },
        { group: "Food", glyph: "☕", name: "hot beverage" },
        { group: "Food", glyph: "🍺", name: "beer mug" },
        { group: "Activities", glyph: "⚽", name: "soccer ball" },
        { group: "Activities", glyph: "🏀", name: "basketball" },
        { group: "Activities", glyph: "🏈", name: "american football" },
        { group: "Activities", glyph: "🎾", name: "tennis" },
        { group: "Activities", glyph: "🎮", name: "video game" },
        { group: "Activities", glyph: "🎲", name: "game die" },
        { group: "Activities", glyph: "🎯", name: "bullseye" },
        { group: "Activities", glyph: "🎨", name: "artist palette" },
        { group: "Activities", glyph: "🎵", name: "musical note" },
        { group: "Activities", glyph: "🎂", name: "birthday cake" },
        { group: "Activities", glyph: "🎉", name: "party popper" },
        { group: "Travel", glyph: "🚗", name: "automobile" },
        { group: "Travel", glyph: "🚌", name: "bus" },
        { group: "Travel", glyph: "🚑", name: "ambulance" },
        { group: "Travel", glyph: "✈", name: "airplane" },
        { group: "Travel", glyph: "🚀", name: "rocket" },
        { group: "Travel", glyph: "🗺", name: "world map" },
        { group: "Travel", glyph: "🏔", name: "snow-capped mountain" },
        { group: "Travel", glyph: "🏖", name: "beach with umbrella" },
        { group: "Objects", glyph: "💻", name: "laptop" },
        { group: "Objects", glyph: "📱", name: "mobile phone" },
        { group: "Objects", glyph: "📷", name: "camera" },
        { group: "Objects", glyph: "⌨", name: "keyboard" },
        { group: "Objects", glyph: "💡", name: "light bulb" },
        { group: "Objects", glyph: "🔒", name: "locked" },
        { group: "Objects", glyph: "🔑", name: "key" },
        { group: "Objects", glyph: "🔔", name: "bell" },
        { group: "Objects", glyph: "📌", name: "pushpin" },
        { group: "Objects", glyph: "✂", name: "scissors" },
        { group: "Objects", glyph: "🛠", name: "hammer and wrench" },
        { group: "Symbols", glyph: "❤", name: "red heart" },
        { group: "Symbols", glyph: "💙", name: "blue heart" },
        { group: "Symbols", glyph: "💚", name: "green heart" },
        { group: "Symbols", glyph: "✅", name: "check mark button" },
        { group: "Symbols", glyph: "❌", name: "cross mark" },
        { group: "Symbols", glyph: "⚠", name: "warning" },
        { group: "Symbols", glyph: "☀", name: "sun" },
        { group: "Symbols", glyph: "☂", name: "umbrella" },
        { group: "Symbols", glyph: "❄", name: "snowflake" },
        { group: "Symbols", glyph: "⚡", name: "high voltage" },
        { group: "Symbols", glyph: "♻", name: "recycling symbol" },
        { group: "Flags", glyph: "🏳️‍🌈", name: "rainbow flag" },
        { group: "Flags", glyph: "🏁", name: "checkered flag" },
        { group: "Flags", glyph: "🚩", name: "triangular flag" },
        { group: "Flags", glyph: "🏴", name: "black flag" }
    ]

    readonly property var asciiEntries: [
        { value: ":)", label: "smile" },
        { value: ":D", label: "big grin" },
        { value: ";)", label: "wink" },
        { value: ":(", label: "frown" },
        { value: ":P", label: "tongue" },
        { value: "<3", label: "heart" },
        { value: "</3", label: "broken heart" },
        { value: ":-)", label: "classic smile" },
        { value: ":'(", label: "crying" },
        { value: "O_o", label: "surprised" },
        { value: "(•_•)", label: "shrug eyes" },
        { value: "(◕‿◕)", label: "happy face" },
        { value: "(＾▽＾)", label: "laughing" },
        { value: "(-_-)", label: "unimpressed" },
        { value: "(¬_¬)", label: "annoyed" },
        { value: "¯\\_(ツ)_/¯", label: "shrug" },
        { value: "(╯°□°）╯︵ ┻━┻", label: "table flip" },
        { value: "┬─┬ノ( º _ ºノ)", label: "table restore" },
        { value: "(╥﹏╥)", label: "sad" },
        { value: "(ง˘•◡•˘)ง", label: "hug" },
        { value: "(•◡•)", label: "content" },
        { value: "\\ (•◡•) /", label: "celebration" },
        { value: "(╬ Ò﹏Ó)", label: "frustrated" },
        { value: "(⌐■_■)", label: "sunglasses" }
    ]

    readonly property var symbolEntries: [
        { value: "©", label: "copyright" },
        { value: "®", label: "registered" },
        { value: "™", label: "trademark" },
        { value: "€", label: "euro" },
        { value: "£", label: "pound" },
        { value: "¥", label: "yen" },
        { value: "¢", label: "cent" },
        { value: "°", label: "degree" },
        { value: "±", label: "plus minus" },
        { value: "×", label: "multiply" },
        { value: "÷", label: "divide" },
        { value: "≠", label: "not equal" },
        { value: "≈", label: "approximately" },
        { value: "∞", label: "infinity" },
        { value: "√", label: "square root" },
        { value: "π", label: "pi" },
        { value: "α", label: "alpha" },
        { value: "β", label: "beta" },
        { value: "Ω", label: "omega" },
        { value: "♥", label: "heart" },
        { value: "♡", label: "outline heart" },
        { value: "★", label: "star" },
        { value: "☆", label: "outline star" },
        { value: "✔", label: "check" },
        { value: "✘", label: "cross" },
        { value: "⚡", label: "lightning" },
        { value: "☂", label: "umbrella" },
        { value: "☃", label: "snowman" },
        { value: "✈", label: "airplane" },
        { value: "☕", label: "coffee" },
        { value: "⚽", label: "football" },
        { value: "⚠", label: "warning" }
    ]

    ListModel {
        id: emojiModel
    }

    ListModel {
        id: asciiModel
    }

    ListModel {
        id: symbolModel
    }

    ListModel {
        id: clipboardModel

        ListElement {
            value: "Hello!"
            label: "greeting"
        }
        ListElement {
            value: "Thanks!"
            label: "thanks"
        }
        ListElement {
            value: "See you soon"
            label: "farewell"
        }
    }

    ListModel {
        id: categoryModel

        ListElement { name: "All" }
        ListElement { name: "Faces" }
        ListElement { name: "Hands" }
        ListElement { name: "Nature" }
        ListElement { name: "Food" }
        ListElement { name: "Activities" }
        ListElement { name: "Travel" }
        ListElement { name: "Objects" }
        ListElement { name: "Symbols" }
        ListElement { name: "Flags" }
    }

    // A plain TextInput gives QML access to the platform clipboard through
    // copy()/paste(); no C++ plugin or extra package is required.
    TextInput {
        id: clipboardProbe
        width: 1
        height: 1
        opacity: 0
        maximumLength: 8192
    }

    function loadEmoji() {
        emojiModel.clear();
        var needle = root.emojiFilter.toLowerCase();
        for (var i = 0; i < root.allEmojis.length; ++i) {
            var entry = root.allEmojis[i];
            var wantedGroup = root.group === "All" || entry.group === root.group;
            var wantedText = needle.length === 0
                || entry.name.indexOf(needle) !== -1
                || entry.group.toLowerCase().indexOf(needle) !== -1
                || entry.glyph === root.emojiFilter;
            if (wantedGroup && wantedText) {
                emojiModel.append(entry);
            }
        }
    }

    function loadStaticModels() {
        asciiModel.clear();
        symbolModel.clear();
        for (var i = 0; i < root.asciiEntries.length; ++i) {
            asciiModel.append(root.asciiEntries[i]);
        }
        for (var j = 0; j < root.symbolEntries.length; ++j) {
            symbolModel.append(root.symbolEntries[j]);
        }
    }

    function refreshClipboard() {
        clipboardProbe.text = "";
        clipboardProbe.select(0, 0);
        clipboardProbe.paste();
        root.currentClipboard = clipboardProbe.text;
    }

    function copyText(value, label) {
        if (!value) {
            return;
        }
        clipboardProbe.text = value;
        clipboardProbe.selectAll();
        clipboardProbe.copy();
        root.copiedText = label && label.length > 0 ? label : value;
        for (var i = clipboardModel.count - 1; i >= 0; --i) {
            if (clipboardModel.get(i).value === value) {
                clipboardModel.remove(i);
            }
        }
        clipboardModel.insert(0, { value: value, label: label || value });
        while (clipboardModel.count > 12) {
            clipboardModel.remove(clipboardModel.count - 1);
        }
    }

    // The glyph is drawn in QML, like Search Center's magnifier, so the panel
    // button stays visible even on icon themes without a smiley icon name.
    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.large * 2
        implicitHeight: Kirigami.Units.iconSizes.large * 2

        PlasmaComponents3.ToolButton {
            id: emojiButton
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.large
            height: Kirigami.Units.iconSizes.large
            icon.name: "face-smile"
            icon.width: Kirigami.Units.iconSizes.medium
            icon.height: Kirigami.Units.iconSizes.medium
            text: i18n("Emoji & Clipboard")
            onClicked: root.expanded = !root.expanded

            contentItem: Item {
                Canvas {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    onPaint: {
                        var ctx = getContext("2d");
                        var size = width;
                        ctx.clearRect(0, 0, size, size);
                        ctx.strokeStyle = Kirigami.Theme.textColor;
                        ctx.fillStyle = Kirigami.Theme.textColor;
                        ctx.lineWidth = Math.max(1.5, size / 12);
                        ctx.beginPath();
                        ctx.arc(size / 2, size / 2, size * 0.38, 0, Math.PI * 2);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(size * 0.38, size * 0.42, size * 0.045, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.beginPath();
                        ctx.arc(size * 0.62, size * 0.42, size * 0.045, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.beginPath();
                        ctx.arc(size / 2, size * 0.44, size * 0.24, Math.PI * 0.15, Math.PI * 0.85);
                        ctx.stroke();
                    }
                    Component.onCompleted: requestPaint()
                }
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 34
        implicitHeight: Kirigami.Units.gridUnit * 32

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Text {
                Layout.fillWidth: true
                text: i18n("Emoji & Clipboard")
                color: Kirigami.Theme.textColor
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.ToolButton {
                    text: i18n("Emoji")
                    icon.name: "face-smile"
                    checkable: true
                    checked: root.tab === 0
                    onClicked: root.tab = 0
                }
                PlasmaComponents3.ToolButton {
                    text: i18n("ASCII")
                    icon.name: "format-text-bold"
                    checkable: true
                    checked: root.tab === 1
                    onClicked: root.tab = 1
                }
                PlasmaComponents3.ToolButton {
                    text: i18n("Symbols")
                    icon.name: "preferences-desktop-font"
                    checkable: true
                    checked: root.tab === 2
                    onClicked: root.tab = 2
                }
                PlasmaComponents3.ToolButton {
                    text: i18n("Clipboard")
                    icon.name: "edit-paste"
                    checkable: true
                    checked: root.tab === 3
                    onClicked: {
                        root.tab = 3;
                        root.refreshClipboard();
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.tab

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            clip: true
                            contentWidth: categoryRow.width
                            flickableDirection: Flickable.HorizontalFlick

                            RowLayout {
                                id: categoryRow
                                spacing: Kirigami.Units.smallSpacing

                                Repeater {
                                    model: categoryModel

                                    delegate: PlasmaComponents3.ToolButton {
                                        text: model.name
                                        checkable: true
                                        checked: root.group === model.name
                                        onClicked: {
                                            root.group = model.name;
                                            root.loadEmoji();
                                        }
                                    }
                                }
                            }
                        }

                        PlasmaComponents3.TextField {
                            Layout.fillWidth: true
                            placeholderText: i18n("Search Google emoji names…")
                            onTextChanged: {
                                root.emojiFilter = text.trim();
                                root.loadEmoji();
                            }
                        }

                        GridView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            cellWidth: Math.max(Kirigami.Units.gridUnit * 3, Math.floor(width / 8))
                            cellHeight: Kirigami.Units.gridUnit * 3
                            model: emojiModel

                            delegate: Item {
                                width: GridView.view.cellWidth
                                height: GridView.view.cellHeight

                                PlasmaComponents3.ToolButton {
                                    anchors.centerIn: parent
                                    width: parent.width - Kirigami.Units.smallSpacing
                                    height: parent.height - Kirigami.Units.smallSpacing
                                    text: model.glyph
                                    onClicked: root.copyText(model.glyph, model.name)

                                    contentItem: Text {
                                        text: model.glyph
                                        font.family: "Noto Color Emoji"
                                        font.pixelSize: Kirigami.Units.gridUnit * 1.6
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    GridView {
                        anchors.fill: parent
                        clip: true
                        cellWidth: Math.max(Kirigami.Units.gridUnit * 8, Math.floor(width / 3))
                        cellHeight: Kirigami.Units.gridUnit * 3
                        model: asciiModel

                        delegate: PlasmaComponents3.ToolButton {
                            width: GridView.view.cellWidth - Kirigami.Units.smallSpacing
                            height: GridView.view.cellHeight - Kirigami.Units.smallSpacing
                            text: model.value
                            onClicked: root.copyText(model.value, model.label)
                        }
                    }
                }

                Item {
                    GridView {
                        anchors.fill: parent
                        clip: true
                        cellWidth: Math.max(Kirigami.Units.gridUnit * 3, Math.floor(width / 6))
                        cellHeight: Kirigami.Units.gridUnit * 3
                        model: symbolModel

                        delegate: PlasmaComponents3.ToolButton {
                            width: GridView.view.cellWidth - Kirigami.Units.smallSpacing
                            height: GridView.view.cellHeight - Kirigami.Units.smallSpacing
                            text: model.value
                            onClicked: root.copyText(model.value, model.label)
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Kirigami.Units.smallSpacing

                        Text {
                            Layout.fillWidth: true
                            text: i18n("Current clipboard")
                            color: Kirigami.Theme.disabledTextColor
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                            color: Kirigami.Theme.backgroundColor
                            border.color: Kirigami.Theme.disabledTextColor
                            border.width: 1
                            radius: Kirigami.Units.smallSpacing

                            Text {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                text: root.currentClipboard || i18n("(empty)")
                                color: root.currentClipboard ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
                                wrapMode: Text.WrapAnywhere
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            PlasmaComponents3.ToolButton {
                                text: i18n("Refresh")
                                icon.name: "view-refresh"
                                onClicked: root.refreshClipboard()
                            }
                            PlasmaComponents3.ToolButton {
                                text: i18n("Copy current")
                                icon.name: "edit-copy"
                                enabled: root.currentClipboard.length > 0
                                onClicked: root.copyText(root.currentClipboard, i18n("clipboard text"))
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: i18n("Session history")
                            color: Kirigami.Theme.disabledTextColor
                            font.bold: true
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: clipboardModel

                            delegate: Item {
                                required property int index

                                width: ListView.view.width
                                height: Kirigami.Units.gridUnit * 2

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Kirigami.Units.smallSpacing

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.value
                                        color: Kirigami.Theme.textColor
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: model.label
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pixelSize: Kirigami.Units.smallSpacing * 2.5
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.copyText(model.value, model.label)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.copiedText ? i18n("Copied: %1", root.copiedText) : i18n("Click an item to copy it; paste with Ctrl+V.")
                color: Kirigami.Theme.disabledTextColor
                elide: Text.ElideRight
            }
        }
    }

    Component.onCompleted: {
        Plasmoid.removeInternalAction("configure");
        root.loadStaticModels();
        root.loadEmoji();
        root.refreshClipboard();
    }
}
