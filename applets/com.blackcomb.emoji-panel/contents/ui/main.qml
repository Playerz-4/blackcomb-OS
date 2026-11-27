/*
    Blackcomb Emoji & Clipboard
    A plain-QML panel opened with Meta+. from anywhere in Plasma. It offers
    Google Noto style emoji, ASCII art/kaomoji, common symbols and a clipboard
    with a session history. Copying an item places it on the system clipboard;
    no SVG artwork, helper binary or new QML module dependency is used.
*/
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
    toolTipSubText: i18n("Meta+. ΓÇö emoji, ASCII art, symbols and clipboard")

    // Google's Noto Color Emoji names are used as the search keywords; the
    // glyphs themselves are rendered by Qt's normal font fallback.
    readonly property var allEmojis: [
        { group: "Faces", glyph: "≡ƒÿÇ", name: "grinning face" },
        { group: "Faces", glyph: "≡ƒÿâ", name: "smiling face with open mouth" },
        { group: "Faces", glyph: "≡ƒÿä", name: "smiling face with smiling eyes" },
        { group: "Faces", glyph: "≡ƒÿü", name: "beaming face" },
        { group: "Faces", glyph: "≡ƒÿå", name: "grinning squinting face" },
        { group: "Faces", glyph: "≡ƒÿà", name: "grinning face with sweat" },
        { group: "Faces", glyph: "≡ƒÿé", name: "face with tears of joy" },
        { group: "Faces", glyph: "≡ƒÖé", name: "slightly smiling face" },
        { group: "Faces", glyph: "≡ƒÖâ", name: "upside-down face" },
        { group: "Faces", glyph: "≡ƒÿë", name: "winking face" },
        { group: "Faces", glyph: "≡ƒÿè", name: "smiling face with smiling eyes" },
        { group: "Faces", glyph: "≡ƒÿç", name: "smiling face with halo" },
        { group: "Faces", glyph: "≡ƒÑ░", name: "smiling face with hearts" },
        { group: "Faces", glyph: "≡ƒÿì", name: "smiling face with heart-eyes" },
        { group: "Faces", glyph: "≡ƒÿÿ", name: "face blowing a kiss" },
        { group: "Faces", glyph: "≡ƒÿï", name: "face savoring food" },
        { group: "Faces", glyph: "≡ƒÿ£", name: "winking face with tongue" },
        { group: "Faces", glyph: "≡ƒñ¬", name: "zany face" },
        { group: "Faces", glyph: "≡ƒñ¿", name: "face with raised eyebrow" },
        { group: "Faces", glyph: "≡ƒºÉ", name: "face with monocle" },
        { group: "Faces", glyph: "≡ƒñô", name: "nerd face" },
        { group: "Faces", glyph: "≡ƒÿÄ", name: "smiling face with sunglasses" },
        { group: "Faces", glyph: "≡ƒÑ│", name: "partying face" },
        { group: "Faces", glyph: "≡ƒÿÅ", name: "smirking face" },
        { group: "Faces", glyph: "≡ƒÿÆ", name: "unamused face" },
        { group: "Faces", glyph: "≡ƒÿ₧", name: "disappointed face" },
        { group: "Faces", glyph: "≡ƒÿö", name: "pensive face" },
        { group: "Faces", glyph: "≡ƒÿó", name: "crying face" },
        { group: "Faces", glyph: "≡ƒÿ¡", name: "loudly crying face" },
        { group: "Faces", glyph: "≡ƒÿñ", name: "face with steam from nose" },
        { group: "Faces", glyph: "≡ƒÿí", name: "enraged face" },
        { group: "Faces", glyph: "≡ƒñ»", name: "exploding head" },
        { group: "Faces", glyph: "≡ƒÿ▒", name: "face screaming in fear" },
        { group: "Faces", glyph: "≡ƒÑ║", name: "pleading face" },
        { group: "Faces", glyph: "≡ƒÿ┤", name: "sleeping face" },
        { group: "Faces", glyph: "≡ƒñö", name: "thinking face" },
        { group: "Faces", glyph: "≡ƒñù", name: "smiling face with open hands" },
        { group: "Faces", glyph: "≡ƒñ¡", name: "face with hand over mouth" },
        { group: "Faces", glyph: "≡ƒÿ╢", name: "face without mouth" },
        { group: "Faces", glyph: "≡ƒÿÉ", name: "neutral face" },
        { group: "Hands", glyph: "≡ƒæì", name: "thumbs up" },
        { group: "Hands", glyph: "≡ƒæÄ", name: "thumbs down" },
        { group: "Hands", glyph: "≡ƒæî", name: "OK hand" },
        { group: "Hands", glyph: "≡ƒñî", name: "pinched fingers" },
        { group: "Hands", glyph: "Γ£î", name: "victory hand" },
        { group: "Hands", glyph: "≡ƒñ₧", name: "crossed fingers" },
        { group: "Hands", glyph: "≡ƒñƒ", name: "love-you gesture" },
        { group: "Hands", glyph: "≡ƒñÿ", name: "sign of the horns" },
        { group: "Hands", glyph: "≡ƒæÅ", name: "clapping hands" },
        { group: "Hands", glyph: "≡ƒÖî", name: "raising hands" },
        { group: "Hands", glyph: "≡ƒñ¥", name: "handshake" },
        { group: "Hands", glyph: "≡ƒÖÅ", name: "folded hands" },
        { group: "Hands", glyph: "≡ƒÆ¬", name: "flexed biceps" },
        { group: "Hands", glyph: "≡ƒæï", name: "waving hand" },
        { group: "Nature", glyph: "≡ƒÉ╢", name: "dog face" },
        { group: "Nature", glyph: "≡ƒÉ▒", name: "cat face" },
        { group: "Nature", glyph: "≡ƒªè", name: "fox face" },
        { group: "Nature", glyph: "≡ƒÉ╗", name: "bear face" },
        { group: "Nature", glyph: "≡ƒÉ╝", name: "panda face" },
        { group: "Nature", glyph: "≡ƒªü", name: "lion face" },
        { group: "Nature", glyph: "≡ƒÉ«", name: "cow face" },
        { group: "Nature", glyph: "≡ƒÉ╖", name: "pig face" },
        { group: "Nature", glyph: "≡ƒÉ╕", name: "frog face" },
        { group: "Nature", glyph: "≡ƒÉ╡", name: "monkey face" },
        { group: "Nature", glyph: "≡ƒî╗", name: "sunflower" },
        { group: "Nature", glyph: "≡ƒîê", name: "rainbow" },
        { group: "Nature", glyph: "≡ƒîÖ", name: "crescent moon" },
        { group: "Nature", glyph: "Γ¡É", name: "star" },
        { group: "Nature", glyph: "≡ƒöÑ", name: "fire" },
        { group: "Food", glyph: "≡ƒìÄ", name: "red apple" },
        { group: "Food", glyph: "≡ƒìè", name: "tangerine" },
        { group: "Food", glyph: "≡ƒìï", name: "lemon" },
        { group: "Food", glyph: "≡ƒìë", name: "watermelon" },
        { group: "Food", glyph: "≡ƒìô", name: "strawberry" },
        { group: "Food", glyph: "≡ƒìÆ", name: "cherries" },
        { group: "Food", glyph: "≡ƒÑæ", name: "avocado" },
        { group: "Food", glyph: "≡ƒìò", name: "pizza" },
        { group: "Food", glyph: "≡ƒìö", name: "hamburger" },
        { group: "Food", glyph: "≡ƒî«", name: "taco" },
        { group: "Food", glyph: "≡ƒì£", name: "steaming bowl" },
        { group: "Food", glyph: "≡ƒì⌐", name: "doughnut" },
        { group: "Food", glyph: "Γÿò", name: "hot beverage" },
        { group: "Food", glyph: "≡ƒì║", name: "beer mug" },
        { group: "Activities", glyph: "ΓÜ╜", name: "soccer ball" },
        { group: "Activities", glyph: "≡ƒÅÇ", name: "basketball" },
        { group: "Activities", glyph: "≡ƒÅê", name: "american football" },
        { group: "Activities", glyph: "≡ƒÄ╛", name: "tennis" },
        { group: "Activities", glyph: "≡ƒÄ«", name: "video game" },
        { group: "Activities", glyph: "≡ƒÄ▓", name: "game die" },
        { group: "Activities", glyph: "≡ƒÄ»", name: "bullseye" },
        { group: "Activities", glyph: "≡ƒÄ¿", name: "artist palette" },
        { group: "Activities", glyph: "≡ƒÄ╡", name: "musical note" },
        { group: "Activities", glyph: "≡ƒÄé", name: "birthday cake" },
        { group: "Activities", glyph: "≡ƒÄë", name: "party popper" },
        { group: "Travel", glyph: "≡ƒÜù", name: "automobile" },
        { group: "Travel", glyph: "≡ƒÜî", name: "bus" },
        { group: "Travel", glyph: "≡ƒÜæ", name: "ambulance" },
        { group: "Travel", glyph: "Γ£ê", name: "airplane" },
        { group: "Travel", glyph: "≡ƒÜÇ", name: "rocket" },
        { group: "Travel", glyph: "≡ƒù║", name: "world map" },
        { group: "Travel", glyph: "≡ƒÅö", name: "snow-capped mountain" },
        { group: "Travel", glyph: "≡ƒÅû", name: "beach with umbrella" },
        { group: "Objects", glyph: "≡ƒÆ╗", name: "laptop" },
        { group: "Objects", glyph: "≡ƒô▒", name: "mobile phone" },
        { group: "Objects", glyph: "≡ƒô╖", name: "camera" },
        { group: "Objects", glyph: "Γî¿", name: "keyboard" },
        { group: "Objects", glyph: "≡ƒÆí", name: "light bulb" },
        { group: "Objects", glyph: "≡ƒöÆ", name: "locked" },
        { group: "Objects", glyph: "≡ƒöæ", name: "key" },
        { group: "Objects", glyph: "≡ƒöö", name: "bell" },
        { group: "Objects", glyph: "≡ƒôî", name: "pushpin" },
        { group: "Objects", glyph: "Γ£é", name: "scissors" },
        { group: "Objects", glyph: "≡ƒ¢á", name: "hammer and wrench" },
        { group: "Symbols", glyph: "Γ¥ñ", name: "red heart" },
        { group: "Symbols", glyph: "≡ƒÆÖ", name: "blue heart" },
        { group: "Symbols", glyph: "≡ƒÆÜ", name: "green heart" },
        { group: "Symbols", glyph: "Γ£à", name: "check mark button" },
        { group: "Symbols", glyph: "Γ¥î", name: "cross mark" },
        { group: "Symbols", glyph: "ΓÜá", name: "warning" },
        { group: "Symbols", glyph: "ΓÿÇ", name: "sun" },
        { group: "Symbols", glyph: "Γÿé", name: "umbrella" },
        { group: "Symbols", glyph: "Γ¥ä", name: "snowflake" },
        { group: "Symbols", glyph: "ΓÜí", name: "high voltage" },
        { group: "Symbols", glyph: "ΓÖ╗", name: "recycling symbol" },
        { group: "Flags", glyph: "≡ƒÅ│∩╕ÅΓÇì≡ƒîê", name: "rainbow flag" },
        { group: "Flags", glyph: "≡ƒÅü", name: "checkered flag" },
        { group: "Flags", glyph: "≡ƒÜ⌐", name: "triangular flag" },
        { group: "Flags", glyph: "≡ƒÅ┤", name: "black flag" }
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
        { value: "(ΓÇó_ΓÇó)", label: "shrug eyes" },
        { value: "(ΓùòΓÇ┐Γùò)", label: "happy face" },
        { value: "(∩╝╛Γû╜∩╝╛)", label: "laughing" },
        { value: "(-_-)", label: "unimpressed" },
        { value: "(┬¼_┬¼)", label: "annoyed" },
        { value: "┬»\\_(πâä)_/┬»", label: "shrug" },
        { value: "(Γò»┬░Γûí┬░∩╝ëΓò»∩╕╡ Γö╗ΓöüΓö╗", label: "table flip" },
        { value: "Γö¼ΓöÇΓö¼πâÄ( ┬║ _ ┬║πâÄ)", label: "table restore" },
        { value: "(ΓòÑ∩╣ÅΓòÑ)", label: "sad" },
        { value: "(α╕ç╦ÿΓÇóΓùíΓÇó╦ÿ)α╕ç", label: "hug" },
        { value: "(ΓÇóΓùíΓÇó)", label: "content" },
        { value: "\\ (ΓÇóΓùíΓÇó) /", label: "celebration" },
        { value: "(Γò¼ ├Æ∩╣Å├ô)", label: "frustrated" },
        { value: "(ΓîÉΓûá_Γûá)", label: "sunglasses" }
    ]

    readonly property var symbolEntries: [
        { value: "┬⌐", label: "copyright" },
        { value: "┬«", label: "registered" },
        { value: "Γäó", label: "trademark" },
        { value: "Γé¼", label: "euro" },
        { value: "┬ú", label: "pound" },
        { value: "┬Ñ", label: "yen" },
        { value: "┬ó", label: "cent" },
        { value: "┬░", label: "degree" },
        { value: "┬▒", label: "plus minus" },
        { value: "├ù", label: "multiply" },
        { value: "├╖", label: "divide" },
        { value: "Γëá", label: "not equal" },
        { value: "Γëê", label: "approximately" },
        { value: "Γê₧", label: "infinity" },
        { value: "ΓêÜ", label: "square root" },
        { value: "╧Ç", label: "pi" },
        { value: "╬▒", label: "alpha" },
        { value: "╬▓", label: "beta" },
        { value: "╬⌐", label: "omega" },
        { value: "ΓÖÑ", label: "heart" },
        { value: "ΓÖí", label: "outline heart" },
        { value: "Γÿà", label: "star" },
        { value: "Γÿå", label: "outline star" },
        { value: "Γ£ö", label: "check" },
        { value: "Γ£ÿ", label: "cross" },
        { value: "ΓÜí", label: "lightning" },
        { value: "Γÿé", label: "umbrella" },
        { value: "Γÿâ", label: "snowman" },
        { value: "Γ£ê", label: "airplane" },
        { value: "Γÿò", label: "coffee" },
        { value: "ΓÜ╜", label: "football" },
        { value: "ΓÜá", label: "warning" }
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
                                        required property string name

                                        text: name
                                        checkable: true
                                        checked: root.group === name
                                        onClicked: {
                                            root.group = name;
                                            root.loadEmoji();
                                        }
                                    }
                                }
                            }
                        }

                        PlasmaComponents3.TextField {
                            Layout.fillWidth: true
                            placeholderText: i18n("Search Google emoji names...")
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
                                required property string glyph
                                required property string name

                                width: GridView.view.cellWidth
                                height: GridView.view.cellHeight

                                PlasmaComponents3.ToolButton {
                                    anchors.centerIn: parent
                                    width: parent.width - Kirigami.Units.smallSpacing
                                    height: parent.height - Kirigami.Units.smallSpacing
                                    text: glyph
                                    onClicked: root.copyText(glyph, name)

                                    contentItem: Text {
                                        text: glyph
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
                            required property string value
                            required property string label

                            width: GridView.view.cellWidth - Kirigami.Units.smallSpacing
                            height: GridView.view.cellHeight - Kirigami.Units.smallSpacing
                            text: value
                            onClicked: root.copyText(value, label)
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
                            required property string value
                            required property string label

                            width: GridView.view.cellWidth - Kirigami.Units.smallSpacing
                            height: GridView.view.cellHeight - Kirigami.Units.smallSpacing
                            text: value
                            onClicked: root.copyText(value, label)
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
                                required property string value
                                required property string label

                                width: ListView.view.width
                                height: Kirigami.Units.gridUnit * 2

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Kirigami.Units.smallSpacing

                                    Text {
                                        Layout.fillWidth: true
                                        text: value
                                        color: Kirigami.Theme.textColor
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: label
                                        color: Kirigami.Theme.disabledTextColor
                                        font.pixelSize: Kirigami.Units.smallSpacing * 2.5
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.copyText(value, label)
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
        try {
            if (typeof Plasmoid.removeInternalAction === "function") {
                Plasmoid.removeInternalAction("configure");
            }
        } catch (e) { console.warn("Blackcomb emoji panel:", e); }
        try { root.loadStaticModels(); root.loadEmoji(); } catch (e) { console.warn("Blackcomb emoji panel:", e); }
        try { root.refreshClipboard(); } catch (e) { console.warn("Blackcomb emoji panel:", e); }
    }
}
