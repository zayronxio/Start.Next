/*
 *  SPDX-FileCopyrightText: zayronxio
 *  SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.plasma.components 3.0 as PC3

import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons // kuser
import org.kde.plasma.private.shell 2.0

import org.kde.kwindowsystem 1.0
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.private.quicklaunch 1.0
import QtQuick.Controls 2.15
import org.kde.kirigami as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import Qt5Compat.GraphicalEffects

Item {
    id: main
    property int sizeImage: Kirigami.Units.iconSizes.large * 2
    property int menuPos: Plasmoid.configuration.displayPosition

    onVisibleChanged: {
        root.visible = !root.visible
    }

    PlasmaExtras.Menu {
        id: contextMenu

        PlasmaExtras.MenuItem {
            action: Plasmoid.internalAction("configure")
        }
    }

    QtObject {
        id: showApps
        property var value: Plasmoid.configuration.viewUser ? 0 : 1
    }

    Plasmoid.status: root.visible ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    PlasmaCore.Dialog {
        id: root

        objectName: "popupWindow"
        flags: Qt.WindowStaysOnTopHint
        //flags: Qt.Dialog | Qt.FramelessWindowHint
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true

        property int iconSize: Kirigami.Units.iconSizes.large
        property int cellSizeHeight: iconSize
                                     + Kirigami.Units.gridUnit * 2
                                     + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                     highlightItemSvg.margins.left + highlightItemSvg.margins.right))
        property int cellSizeWidth: cellSizeHeight

        property bool searching: (searchField.text != "")

        property bool showFavorites

        onVisibleChanged: {
            if (visible) {
                root.showFavorites = Plasmoid.configuration.showFavoritesFirst
                var pos = popupPosition(width, height);
                x = pos.x;
                y = pos.y;
                reset();
                animation1.start()
            }else{
                rootItem.opacity = 0
            }
        }

        onHeightChanged: {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
        }

        onWidthChanged: {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
        }

        function toggle(){
            main.visible =  !main.visible
        }


        function reset() {
            searchField.text = "";

            if(showFavorites)
                globalFavoritesGrid.tryActivate(0,0)
            else
                mainColumn.visibleGrid.tryActivate(0,0)


        }

        function popupPosition(width, height) {
            var screenAvail = kicker.availableScreenRect;
            var screen = kicker.screenGeometry;
            var panelH = screen.height - screenAvail.height;
            var panelW = screen.width - screenAvail.width;
            var horizMidPoint = screen.x + (screen.width / 2);
            var vertMidPoint = screen.y + (screen.height / 2);
            var appletTopLeft = parent.mapToGlobal(0, 0);

            function calculatePosition(x, y) {
                return Qt.point(x, y);
            }

            if (menuPos === 0) {
                switch (plasmoid.location) {
                    case PlasmaCore.Types.BottomEdge:
                        var x = appletTopLeft.x < screen.width - width ? appletTopLeft.x : screen.width - width - 8;
                        var y = screen.height - height - panelH - Kirigami.Units.gridUnit / 2;
                        return calculatePosition(x, y);

                    case PlasmaCore.Types.TopEdge:
                        x = appletTopLeft.x < screen.width - width ? appletTopLeft.x + panelW - Kirigami.Units.gridUnit / 3 : screen.width - width;
                        y = panelH + Kirigami.Units.gridUnit / 2;
                        return calculatePosition(x, y);

                    case PlasmaCore.Types.LeftEdge:
                        x = appletTopLeft.x + panelW + Kirigami.Units.gridUnit / 2;
                        y = appletTopLeft.y < screen.height - height ? appletTopLeft.y : appletTopLeft.y - height + iconUser.height / 2;
                        return calculatePosition(x, y);

                    case PlasmaCore.Types.RightEdge:
                        x = appletTopLeft.x - width - Kirigami.Units.gridUnit / 2;
                        y = appletTopLeft.y < screen.height - height ? appletTopLeft.y : screen.height - height - Kirigami.Units.gridUnit / 5;
                        return calculatePosition(x, y);

                    default:
                        return;
                }
            } else if (menuPos === 2) {
                x = horizMidPoint - width / 2;
                y = screen.height - height - panelH - Kirigami.Units.gridUnit / 2;
                return calculatePosition(x, y);
            } else if (menuPos === 1) {
                x = horizMidPoint - width / 2;
                y = vertMidPoint - height / 2;
                return calculatePosition(x, y);
            }
        }

        FocusScope {
            id: rootItem
            Layout.minimumWidth:  Kirigami.Units.gridUnit*30
            Layout.maximumWidth:  minimumWidth
            Layout.minimumHeight: (root.cellSizeHeight *  Plasmoid.configuration.numberRows) + searchField.implicitHeight + (Plasmoid.configuration.viewUser ? main.sizeImage*0.5 : Kirigami.Units.gridUnit * 1.5 ) +  Kirigami.Units.gridUnit * 6.2
            Layout.maximumHeight: (root.cellSizeHeight *  Plasmoid.configuration.numberRows) + searchField.implicitHeight + (Plasmoid.configuration.viewUser ? main.sizeImage*0.5 : Kirigami.Units.gridUnit * 1.5 ) +  Kirigami.Units.gridUnit * 6.2
            focus: true


            KCoreAddons.KUser {   id: kuser  }
            Logic { id: logic }


            OpacityAnimator { id: animation1; target: rootItem; from: 0; to: 1; easing.type: Easing.InOutQuad;  }

            P5Support.DataSource {
                id: pmEngine
                engine: "powermanagement"
                connectedSources: ["PowerDevil", "Sleep States"]
                function performOperation(what) {
                    var service = serviceForSource("PowerDevil")
                    var operation = service.operationDescription(what)
                    service.startOperationCall(operation)
                }
            }

            P5Support.DataSource {
                id: executable
                engine: "executable"
                connectedSources: []
                onNewData: {
                    var exitCode = data["exit code"]
                    var exitStatus = data["exit status"]
                    var stdout = data["stdout"]
                    var stderr = data["stderr"]
                    exited(sourceName, exitCode, exitStatus, stdout, stderr)
                    disconnectSource(sourceName)
                }
                function exec(cmd) {
                    if (cmd) {
                        connectSource(cmd)
                    }
                }
                signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
            }

            PlasmaExtras.Highlight  {
                id: delegateHighlight
                visible: false
                z: -1 // otherwise it shows ontop of the icon/label and tints them slightly
            }

            Kirigami.Heading {
                id: dummyHeading
                visible: false
                width: 0
                level: 5
            }

            TextMetrics {
                id: headingMetrics
                font: dummyHeading.font
            }

            KSvg.FrameSvgItem {
                id : headingSvg
                width: parent.height + backgroundSvg.margins.bottom + backgroundSvg.margins.top
                //height:  root.cellSizeHeight * Plasmoid.configuration.numberRows  + Kirigami.Units.gridUnit * 2 + backgroundSvg.margins.bottom - 1 //<>+ paginationBar.height
                height: parent.width*.4 + backgroundSvg.margins.left
                y:  - backgroundSvg.margins.top
                x: parent.width + backgroundSvg.margins.left
                imagePath: "widgets/plasmoidheading"
                prefix: "header"
                opacity: 0.6
                transform: Rotation {
                    angle: 90
                    origin.x: width / 2
                    origin.y: height / 2
                }
            }




            RowLayout {
                id: rowSearchField
                width: parent.width*.4
                anchors{
                    top: parent.top
                    topMargin: Kirigami.Units.gridUnit*1
                    left: parent.left
                    leftMargin: (parent.width*.6 - width)/2
                    margins: Kirigami.Units.smallSpacing
                }


                PC3.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: i18n("Type here to search ...")
                    topPadding: 10
                    bottomPadding: 10
                    leftPadding: ((parent.width - width)/2) + Kirigami.Units.iconSizes.small*2
                    text: ""
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    onTextChanged: {
                        runnerModel.query = text;
                    }

                    Keys.onPressed: (event)=> {
                                        if (event.key === Qt.Key_Escape) {
                                            event.accepted = true;
                                            if(root.searching){
                                                searchField.clear()
                                            } else {
                                                root.toggle()
                                            }
                                        }

                                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                            event.accepted = true;
                                            if(root.showFavorites)
                                            globalFavoritesGrid.tryActivate(0,0)
                                            else
                                            mainColumn.visibleGrid.tryActivate(0,0)
                                        }
                                    }

                    function backspace() {
                        if (!root.visible) {
                            return;
                        }
                        focus = true;
                        text = text.slice(0, -1);
                    }

                    function appendText(newText) {
                        if (!root.visible) {
                            return;
                        }
                        focus = true;
                        text = text + newText;
                    }
                    Kirigami.Icon {
                        source: 'search'
                        anchors {
                            left: searchField.left
                            verticalCenter: searchField.verticalCenter
                            leftMargin: Kirigami.Units.smallSpacing * 2

                        }
                        height: Kirigami.Units.iconSizes.small
                        width: height
                    }

                }

                Item {
                    Layout.fillWidth: true
                }


            }
            ComboBox {
                textRole: "text"
                valueRole: "value"
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: searchField.topPadding + searchField.height + Kirigami.Units.gridUnit *1.5
                anchors.leftMargin: parent.width - headingSvg.height - width - 16
                id: showAppsSelector

                model: ListModel {
                    id: two
                    ListElement {
                        text: i18n("favorites")
                        value: 0
                    }
                    ListElement {
                        text: i18n("All apps")
                        value: 1
                    }
                }

                onActivated: showApps.value = currentValue // Actualiza showApps.value al cambiar la selección

                onAccepted: {
                    currentIndex = indexOfValue(showApps.value)
                }
            }

            //
            //
            //
            //
            //

            ItemGridView {
                id: globalFavoritesGrid
                visible: showApps.value === 0
                anchors {
                    top: rowSearchField.bottom
                    topMargin: Kirigami.Units.gridUnit * 3
                }

                dragEnabled: true
                dropEnabled: true
                width: rootItem.width*.6
                height: root.cellSizeHeight * Plasmoid.configuration.numberRows
                focus: true
                cellWidth:   96
                cellHeight:  root.cellSizeHeight
                iconSize:    32
                onKeyNavUp: searchField.focus = true
                Keys.onPressed:(event)=> {
                                   if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                                       searchField.focus = true;
                                       return
                                   }
                                   if (event.key === Qt.Key_Tab) {
                                       event.accepted = true;
                                       searchField.focus = true
                                   }
                               }
            }
            /* zayron code*/
            /*
             *
             */

            Column {
                id: places
                width: headingSvg.height*.8
                height: parent.height - dialog.height / 2 - Kirigami.Units.gridUnit * 2.8
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                ListModel {
                    id: userDirs
                    ListElement {
                        text: i18n("Home")
                        icon: "user-home-symbolic"
                        command: "xdg-open $HOME"
                    }
                    ListElement {
                        text: i18n("Documents")
                        icon: "folder-documents-symbolic"
                        command: "xdg-open $(xdg-user-dir DOCUMENTS)"
                    }
                    ListElement {
                        text: i18n("Music")
                        icon: "folder-music-symbolic"
                        command: "xdg-open $(xdg-user-dir MUSIC)"
                    }
                    ListElement {
                        text: i18n("Pictures")
                        icon: "folder-pictures-symbolic"
                        command: "xdg-open $(xdg-user-dir PICTURES)"
                    }
                    ListElement {
                        text: i18n("Videos")
                        icon: "folder-videos-symbolic"
                        command: "xdg-open $(xdg-user-dir VIDEOS)"
                    }
                    ListElement {
                        text: i18n("System Settings")
                        icon: "configure"
                        command: "systemsettings"
                    }
                }
                Column {
                    width: parent.width
                    height: parent.height

                    ListView {
                        id: listPlaces
                        model: userDirs
                        width: parent.width
                        height: parent.height
                        delegate: Component {
                            Item {
                                width: parent.width
                                height: 40 // Altura total del elemento
                                Column {
                                    width: parent.width
                                    Row {
                                        width: parent.width
                                        height: 24 // Altura del contenido
                                        spacing: 5
                                        Kirigami.Icon {
                                            source: model.icon
                                            width: height
                                            color: Kirigami.Theme.textColor
                                            height: 24 // Altura del icono
                                        }
                                        Text {
                                            width: (parent.width - height)
                                            text: model.text
                                            height: 24
                                            color: Kirigami.Theme.textColor
                                            font.pixelSize: 12
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 16 // Espacio adicional
                                        color: "transparent"
                                    }
                                }
                                MouseArea {
                                    width: parent.width
                                    height: parent.height
                                    anchors.centerIn: parent
                                    onClicked: {
                                        executable.exec(model.command);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //
            //
            //
            //
            //
            Item {
                id: shutdownIcon
                width: 24
                height: 24
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Kirigami.Units.gridUnit*2
                anchors.right: parent.right
                anchors.rightMargin: parent.width*.2 - width/2
                Kirigami.Icon {
                    source: "system-shutdown"
                    color: Kirigami.Theme.textColor
                    width: parent.width
                    height: parent.height
                }
                MouseArea {
                    height: parent.height
                    width: parent.width
                    anchors.centerIn: parent
                    onClicked: {
                        pmEngine.performOperation("requestShutDown")
                    }
                }
            }
            Item {
                width: textuser.implicitWidth
                height: textuser.implicitHeight
                visible: true
                anchors.top: parent.top
                anchors.topMargin: iconUser.height/2 + Kirigami.Units.gridUnit * .5
                anchors.right: parent.right
                anchors.rightMargin: (headingSvg.height - width)/2

                Text {
                    width: parent.width
                    height: parent.height
                    id: textuser
                    text:  i18n("Hi, ")+ kuser.fullName
                    font.bold: true
                    font.pixelSize: 17
                    color: Kirigami.Theme.textColor
                }
            }
            //
            //
            //
            //
            //
            Item{
                id: mainGrids
                visible: !globalFavoritesGrid.visible

                anchors {
                    top: rowSearchField.bottom
                    topMargin: Kirigami.Units.gridUnit * 3
                    //left: parent.left
                    //right: parent.right

                }

                width: rootItem.width
                height: root.cellSizeHeight *  Plasmoid.configuration.numberRows

                Item {
                    id: mainColumn
                    //width: root.cellSize *  Plasmoid.configuration.numberColumns + Kirigami.Units.gridUnit
                    width: rootItem.width
                    height: root.cellSizeHeight * Plasmoid.configuration.numberRows

                    property Item visibleGrid: allAppsGrid

                    function tryActivate(row, col) {
                        if (visibleGrid) {
                            visibleGrid.tryActivate(row, col);
                        }
                    }

                    ItemGridView {
                        id: allAppsGrid

                        //width: root.cellSize *  Plasmoid.configuration.numberColumns + Kirigami.Units.gridUnit
                        width: rootItem.width*.6
                        Layout.maximumWidth: rootItem.width*.6
                        height: root.cellSizeHeight * Plasmoid.configuration.numberRows
                        cellWidth:   96
                        cellHeight:  root.cellSizeHeight
                        iconSize:    32
                        enabled: (opacity == 1) ? 1 : 0
                        z:  enabled ? 5 : -1
                        dropEnabled: false
                        dragEnabled: false
                        opacity: root.searching ? 0 : 1
                        onOpacityChanged: {
                            if (opacity == 1) {
                                //allAppsGrid.scrollBar.flickableItem.contentY = 0;
                                mainColumn.visibleGrid = allAppsGrid;
                            }
                        }
                        onKeyNavUp: searchField.focus = true
                    }

                    ItemMultiGridView {
                        id: runnerGrid
                        width: rootItem.width*.6
                        height: root.cellSizeHeight * Plasmoid.configuration.numberRows
                        cellWidth:   root.cellSizeWidth
                        cellHeight:  root.cellSizeHeight
                        enabled: (opacity == 1.0) ? 1 : 0
                        z:  enabled ? 5 : -1
                        model: runnerModel
                        grabFocus: true
                        opacity: root.searching ? 1.0 : 0.0
                        onOpacityChanged: {
                            if (opacity == 1.0) {
                                mainColumn.visibleGrid = runnerGrid;
                            }
                        }
                        onKeyNavUp: searchField.focus = true
                    }

                    Keys.onPressed: (event)=> {
                                        if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                                            searchField.focus = true;
                                            return
                                        }
                                        if (event.key === Qt.Key_Tab) {
                                            event.accepted = true;
                                            searchField.focus = true
                                        } else if (event.key === Qt.Key_Backspace) {
                                            event.accepted = true;
                                            if(root.searching)
                                            searchField.backspace();
                                            else
                                            searchField.focus = true
                                        } else if (event.key === Qt.Key_Escape) {
                                            event.accepted = true;
                                            if(root.searching){
                                                searchField.clear()
                                            } else {
                                                root.toggle()
                                            }
                                        } else if (event.text !== "") {
                                            event.accepted = true;
                                            searchField.appendText(event.text);
                                        }
                                    }
                }
            }




            Keys.onPressed: (event)=> {
                                if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                                    searchField.focus = true;
                                    return
                                }
                                if (event.key === Qt.Key_Escape) {
                                    event.accepted = true;
                                    if (root.searching) {
                                        reset();
                                    } else {
                                        root.visible = false;
                                    }
                                    return;
                                }

                                if (searchField.focus) {
                                    return;
                                }

                                if (event.key === Qt.Key_Backspace) {
                                    event.accepted = true;
                                    searchField.backspace();
                                }  else if (event.text !== "") {
                                    event.accepted = true;
                                    searchField.appendText(event.text);
                                }
                            }

        }

        function setModels(){
            globalFavoritesGrid.model = globalFavorites
            allAppsGrid.model = rootModel.modelForRow(0);
        }

        Component.onCompleted: {
            rootModel.refreshed.connect(setModels)
            reset();
            rootModel.refresh();
        }
    }



    PlasmaCore.Dialog {
        id: dialog

        width:  main.sizeImage*.85
        height: width

        visible: root.visible

        y: root.y - sizeImage/2
        x: root.x + root.width*.81 - sizeImage/2

        objectName: "popupWindowIcon"
        //flags: Qt.WindowStaysOnTopHint
        type: "Notification"
        location: PlasmaCore.Types.Floating

        hideOnWindowDeactivate: false
        backgroundHints: PlasmaCore.Dialog.NoBackground

        mainItem:  Rectangle{
            width: main.sizeImage*.85
            height: width
            color: 'transparent'
            Rectangle {
                id: mask
                width: parent.width
                height: parent.height
                visible: false
                radius: height/2
            }
            Image {
                id: iconUser
                source: kuser.faceIconUrl
                cache: false
                visible: source !== "" && Plasmoid.configuration.viewUser
                width: parent.width
                height: parent.height
                fillMode: Image.PreserveAspectFit
                layer.enabled:true
                state: "hide"
                states: [
                    State {
                        name: "show"
                        when: dialog.visible
                        PropertyChanges { target: iconUser; y: 0; opacity: 1; }
                    },
                    State {
                        name: "hide"
                        when: !dialog.visible
                        PropertyChanges { target: iconUser; y: sizeImage/3 ; opacity: 0; }
                    }
                ]
                transitions: Transition {
                    PropertyAnimation { properties: "opacity,y"; easing.type: Easing.InOutQuad; }
                }

                layer.effect: OpacityMask {
                    maskSource: mask
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: KCM.KCMLauncher.openSystemSettings("kcm_users")
                }
            }
        }
    }
}
