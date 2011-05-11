/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1 as Labs
import MeeGo.Components 0.1
import "home.js" as Code

Item {
    id: mainGrid

    property bool customizeMode: false
    onCustomizeModeChanged: {
        if (customizeMode)
        {
            // Add a new empty page so that it is possible to move an
            // icon/widget to the next page
            if (listView.model.count < 9)
            {
                Code.assignedSeats.push([]);
                listView.model.append({'dpage': listView.model.count });
            }
        }
        else
        {
            Code.removeEmptyPages();
            while (listView.model.count > Code.assignedSeats.length)
                listView.model.remove(listView.model.count - 1);
        }
    }

    property int activePager: -1
    onActivePagerChanged: {
        if (activePager == -1)
        {
            pageTimer.running = false;
        }
        else
        {
            pageTimer.running = true;
        }
    }

    Timer {
        id: customizeTimer
        interval:  3000
        onTriggered: {
            customizeMode = false;
        }
    }

    Timer {
        id: pageTimer
        interval: 1000
        onTriggered: {
            if (activePager != -1)
            {
                if (activePager < 10)
                {
                    listView.currentIndex = activePager;
                }
                else if (activePager == 10 && listView.currentIndex > 0)
                {
                    listView.currentIndex = listView.currentIndex - 1;
                }
                else if (activePager == 11 && listView.currentIndex < 9 && listView.currentIndex < listView.count - 1)
                {
                    listView.currentIndex = listView.currentIndex + 1;
                }

                activePager = -1;
            }
        }
    }

    Labs.ApplicationsModel {
        id: appsModel
        type: "Application"
        directories: [ "/usr/share/meego-ux-appgrid/virtual-applications", "/usr/share/meego-ux-appgrid/applications", "/usr/share/applications", "~/.local/share/applications" ]
        onAppsChanged: {
            Code.assignSeats(apps);
            Code.processWaitingList();
            Code.removeNullDesktops();
            Code.removeEmptyPages();
            while (Code.assignedSeats.length > listView.model.count)
            {
                listView.model.append({'dpage': listView.model.count});
            }
            while (listView.model.count > Code.assignedSeats.length)
                listView.model.remove(listView.model.count - 1);
            listView.relayout();
        }
    }
    Labs.ApplicationsModel {
        id: widgetsModel
        type: "Widget"
        directory: "~/.config/MeeGo/widgets"
        onAppsChanged: {
            var newpage = false;
            Code.removeNullDesktops();
            var targetPage = Code.assignNewSeats(apps);
            Code.removeEmptyPages();
            while (Code.assignedSeats.length > listView.model.count)
            {
                newpage = true;
                listView.model.append({'dpage': listView.model.count});
            }
            while (listView.model.count > Code.assignedSeats.length)
                listView.model.remove(listView.model.count - 1);
            if (targetPage != -1)
            {
               if (targetPage == listView.currentIndex)
                   listView.relayout();
               else
                   listView.currentIndex = targetPage;
            }
        }
    }

    Component {
        id: confirmDialogComponent
        Item {
            id: confirmDialogInstance
            width: mainGrid.width
            height: mainGrid.height
            opacity: 0.0
            onOpacityChanged: {
                if (opacity == 0.0)
                {
                    confirmDialogInstance.destroy();
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: 250; }
            }

            property variant desktop
            property bool uninstallable: false
            onDesktopChanged: {
                uninstallable = !desktop.contains("Desktop Entry/X-MEEGO-CORE-UX");
            }

            Component.onCompleted: {
                opacity = 1.0;
            }

            MouseArea {
                anchors.fill: parent
                onClicked: confirmDialogInstance.opacity = 0.0
            }
            BorderImage {
                id: dialog
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height/2
                border.top: 14
                border.left: 20
                border.right: 20
                border.bottom: 20
                source: "image://theme/notificationBox_bg"
                Text {
                    id: dialogTitle
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: qsTr("Delete \"%1\"").arg(confirmDialogInstance.desktop.title)
                    font.pointSize: 20
                    color: theme_fontColorNormal
                }
                Text {
                    id: dialogBodyMsg
                    anchors.fill: parent
                    anchors.topMargin: dialogTitle.y + dialogTitle.height
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    anchors.bottomMargin: 20 + dialogButtonBox.height
                    color: theme_fontColorNormal
                    font.pointSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: confirmDialogInstance.uninstallable ? qsTr("Deleting \"%1\" will also delete all of its data").arg(confirmDialogInstance.desktop.title) : qsTr("\"%1\" can not be deleted").arg(confirmDialogInstance.desktop.title)
                }
                Item {
                    id: dialogButtonBox
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 20
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    width: parent.width - 40
                    height: parent.height/5
                    Button {
                        anchors.fill: parent
                        anchors.rightMargin: parent.width/2
                        opacity: confirmDialogInstance.uninstallable ? 1.0 : 0.0
                        text: qsTr("Delete")
                        bgSourceUp: "image://theme/btn_blue_up"
                        bgSourceDn: "image://theme/btn_blue_up"
                        onClicked: {
                            confirmDialogInstance.desktop.uninstall();
                            confirmDialogInstance.opacity = 0.0;
                        }
                    }

                    Button {
                        anchors.fill: parent
                        anchors.leftMargin: confirmDialogInstance.uninstallable ? parent.width/2 : 0
                        text: qsTr("Cancel")
                        bgSourceUp: "image://theme/btn_red_up"
                        bgSourceDn: "image://theme/btn_red_up"
                        onClicked: confirmDialogInstance.opacity = 0.0
                    }
                }
            }
        }
    }

    Component {
        id: itemComponent
        Item {
            id: itemInstance
            width: drawingArea.cellWidth * desktop.width
            height: drawingArea.cellHeight * desktop.height
            x: column * drawingArea.cellWidth
            y: (drawingArea.cellHeight * (4 - row)) % parent.height
            property int row: desktop.row
            property int column: desktop.column
            property alias selected: widgetContainer.selected
            property alias validPosition: widgetContainer.validPosition
            property int index: 0
            property alias container: widgetContainer
            property variant desktop

            property int xoffset: 0
            property int yoffset: 0
            property int originalX: 0
            property int originalY: 0

            Component {
                id: connectionsComponent
                Connections {
                    target: desktop
                    onAboutToDelete: {
                        itemInstance.destroy();
                    }
                }
            }
            function initPressed(mouseX, mouseY) {
                originalX = x;
                originalY = y;
                xoffset = mouseX;
                yoffset = mouseY;

                customizeTimer.running = false;
                activePager = -1;

                var target = listView.landingPad;
                target.row = desktop.row;
                target.column = desktop.column;
                target.cellWidth = desktop.width;
                target.cellHeight = desktop.height;
            }

            function startDrag(mouseX, mouseY) {
                customizeMode = true;
                widgetContainer.selected = true;
                listView.landingPad.opacity = 0.5;
                itemInstance.parent = drawingArea;
            }

            function endDrag(mouseX, mouseY) {
                selected = false;

                var repage = desktop.row != 0 && listView.currentItem.page != desktop.page;
                var target = listView.landingPad;

                if (!trash.active && validPosition && (target.row != desktop.row || target.column != desktop.column || listView.currentItem.page != desktop.page))
                {
                    if (target.row == 0)
                    {
                        itemInstance.parent = dockContainer;
                    }
                    else
                    {
                        itemInstance.parent = listView.currentItem;
                    }

                    if (desktop.row == 0 && target.row > 0)
                    {
                        // Move from the dock to the grid
                        Code.assignedSeats[listView.currentIndex].push(desktop);
                        Code.pluckFromDock(desktop);
                    }
                    else if (desktop.row > 0 && target.row == 0)
                    {
                        // Move from the grid to the dock
                        Code.dock.push(desktop);
                        Code.pluckFromPage(desktop);
                    }

                    // Kick anyone out of our new seat
                    var endingRow = target.row - (desktop.height - 1);
                    var endingColumn = target.column + (desktop.width - 1);
                    Code.freeSeatingBlock(desktop, target.row, endingRow, target.column, endingColumn, listView.currentItem.page);

                    if (target.row != 0 && repage)
                        Code.pluckFromPage(desktop);

                    // Persist the change
                    desktop.row = target.row;
                    desktop.column = target.column;
                    desktop.page = target.row == 0 ? 0 : listView.currentItem.page;

                    if (target.row != 0 && repage)
                        Code.insertIntoPage(desktop);

                    // Cleanup the waiting list
                    Code.processWaitingList();

                    // Cleanup any orphaned grid children
                    for (var i = listView.currentItem.children.length; i > 0; i--)
                    {
                        try
                        {
                            var item = listView.currentItem.children[i];
                            if (item.desktop.page != listView.currentIndex)
                                item.destroy();
                        }
                        catch (err)
                        {
                            // This isn't an icon/widget item
                        }
                    }

                    // Cleanup any orphaned dock childern
                    for (var i = dockContainer.children.length; i > 0; i--)
                    {
                        try
                        {
                            var item = dockContainer.children[i];
                            if (item.row != 0)
                            {
                                if (item.desktop.page == listView.currentIndex)
                                    // have a heart... provide a home
                                    item.parent = listView.currentItem;
                                else
                                    // oh.. the humanity!
                                    item.destroy();
                            }
                        }
                        catch (err)
                        {
                            // This isn't an icon/widget item
                        }
                    }
                }
                else
                {
                    if (itemInstance.desktop.row == 0)
                    {
                        itemInstance.parent = dockContainer;
                    }
                    else
                    {
                        itemInstance.parent = listView.currentItem;
                    }

                    if (trash.active)
                    {
                        trash.active = false;
                        if (itemInstance.desktop.type == "Widget")
                        {
                            itemInstance.desktop.uninstall();
                        }
                        else
                        {
                            // Verify that the user really wishes to uninstall
                            var dialog = confirmDialogComponent.createObject(mainGrid);
                            dialog.desktop = itemInstance.desktop;
                        }
                    }

                    if (repage)
                    {
                        itemInstance.destroy();
                    }
                }
                target.opacity = 0.0;
                customizeTimer.running = true;

                // Let the item snap into its correct grid location
                itemTranslate.x = 0;
                itemTranslate.y = 0;
            }

            function updateDrag(mouseX, mouseY) {
                var pos = mapToItem(drawingArea, mouseX, mouseY);
                var targetRow = Code.position2Row(drawingArea.height - pos.y, drawingArea.height - mouseY);
                var targetColumn = Code.position2Column(pos.x, drawingArea.width + mouseX);

                if (drawingArea.childAt(pos.x, pos.y) == trash)
                    trash.active = true;
                else
                    trash.active = false;

                var pagerPos = mapToItem(pager, mouseX, mouseY);
                var pagerItem = pager.childAt(pagerPos.x, pagerPos.y);
                if (pagerItem)
                    activePager = pagerItem.pageIndex;
                else if (pos.x < drawingArea.cellWidth/4)
                    activePager = 10;
                else if (pos.x > listView.width - drawingArea.cellWidth/4)
                    activePager = 11;
                else
                    activePager = -1;

                validPosition = Code.isBlockAvailable(desktop, desktop.priority + 1, targetRow, targetRow - (desktop.height - 1), targetColumn, targetColumn + (desktop.width - 1), listView.currentItem.page);
                var pos = mapToItem(deviceScene, mouseX, mouseY);
                itemTranslate.x = pos.x - xoffset - originalX;
                itemTranslate.y = pos.y - yoffset - originalY;

                var target = listView.landingPad;
                target.cellWidth = desktop.width;
                target.cellHeight = desktop.height;
                if (validPosition)
                {
                    target.row = targetRow;
                    target.column = targetColumn;
                }
                else
                {
                    target.row = desktop.row;
                    target.column = desktop.column;
                }
            }

            onDesktopChanged: {
                if (desktop != null)
                {
                    connectionsComponent.createObject(itemInstance);
                    if (desktop.type == "Application")
                    {
                        var source = "AppIcon.qml";
                    }
                    else
                    {
                        var source = desktop.value("Desktop Entry/X-MEEGO-WIDGET-SOURCE");
                    }
                    var c = Qt.createComponent(source);
                    var o = c.createObject(widgetContainer);
                    o.width = itemInstance.width;
                    o.height = itemInstance.height;
                    try
                    {
                        o.desktop = desktop;
                    }
                    catch (err)
                    {
                        // Widget does not have a desktop property
                    }
                }
            }
            Behavior on scale {
                PropertyAnimation { duration: 100 }
            }
            MouseArea {
                anchors.fill: parent
                onPressed: initPressed(mouseX, mouseY)
                onClicked: widgetContainer.clicked(mouse)
                onPressAndHold: startDrag(mouseX, mouseY)
                onReleased: {
                    if (parent.selected)
                        endDrag(mouseX, mouseY);
                }
                onPositionChanged: {
                    if (parent.selected)
                        updateDrag(mouseX, mouseY);
                }
            }
            Rectangle {
                id: widgetBackground
                anchors.fill: parent
                anchors.margins: 5
                opacity: 0.0
                color: "white"
                radius: 10
            }
            Item {
                id: widgetContainer
                anchors.fill: parent
                property bool selected: false
                property bool validPosition: true
                signal clicked(variant mouse)
                scale: 1.0
                states: [
                    State {
                        name: "customized"
                        when: customizeMode && !selected && desktop.row > 0
                        PropertyChanges {
                            target: widgetBackground
                            opacity: 0.2
                            color: "yellow"
                        }
                    }
                ]
                transitions: [
                    Transition {
                        to: "customized"
                        reversible: true
                        PropertyAnimation {
                            properties: "color,opacity"
                            duration: 500
                            easing.type: Easing.InSine
                        }
                    }
                ]

            }
            MouseArea {
                anchors.fill: parent
                enabled: customizeMode
                onPressed: {
                    initPressed(mouseX, mouseY);
                    startDrag(mouseX, mouseY);
                }
                onReleased: {
                    endDrag(mouseX, mouseY);
                }
                onPositionChanged: {
                    updateDrag(mouseX, mouseY);
                }
            }
            states: [
                State {
                    name: "selected"
                    when: itemInstance.selected
                    PropertyChanges {
                        target: itemInstance
                        scale: 1.1
                        opacity: 0.6
                        z: 100
                    }
                }
            ]
            transform: Translate {
                // Dragging this item is done via this Translate element so that
                // the original toplevel x and y bindings are preserved.  This
                // way we are always assured that an icon/widget will snap into
                // the correct location since once you assign an objects
                // property from inside Javascript, then the binding is lost
                // and changes to the desktop row/column will no longer result
                // in the icon/widget automatically snapping into the correct
                // location.
                id: itemTranslate
                x: 0
                y: 0
            }
        }
    }
    Item {
        id: drawingArea
        width: parent.width
        height: parent.height
        property int cellWidth: width/4
        property int cellHeight: height/5

        property bool switcherActive: false

        focus: !switcherActive && !scene.locked
        Item {
            id: dockContainer
            anchors.fill: parent
            BorderImage {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height/5
                source: "image://meegotheme/widgets/apps/home-screen/shelf"
            }
        }

        ListView {
            id: listView
            anchors.top:  parent.top
            width: parent.width
            height: parent.height - parent.height/5
            interactive: !customizeMode
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveSpeed: 3000
            model: ListModel {}
            Component.onCompleted: {
                Code.assignSeats(appsModel.apps);
                Code.assignSeats(widgetsModel.apps);
                Code.processWaitingList();
                Code.removeEmptyPages();
                for (var page = 0; page < Code.getPageCount(); page++)
                {
                    model.append({'dpage': page });
                }
                // populate the dock
                Code.populateDock(dockContainer);
            }

            function appAtPosition(row, column)
            {
                for (var i = 0; i < currentItem.children.length; i++)
                {
                    var e = currentItem.children[i];
                    if (e.row == row && e.column == column)
                        return e;
                }
            }

            function relayout()
            {
                Code.cleanup(listView.currentItem);
                Code.populateGrid(listView.currentItem, listView.currentIndex);
            }

            property alias landingPad: landingPadItem
            Rectangle {
                id: landingPadItem
                color: "slategray"
                opacity: 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }

                radius: 10
                width: drawingArea.cellWidth * cellWidth
                height: drawingArea.cellHeight * cellHeight
                x: column * drawingArea.cellWidth
                y: drawingArea.cellHeight * (4 - row)
                property int row: 0
                property int column: 0
                property int cellWidth: 0
                property int cellHeight: 0
            }


            delegate: Item {
                id: dinstance
                width: listView.width
                height: listView.height

                property int page: dpage;

                Component.onCompleted: { Code.populateGrid(dinstance, page); }
                MouseArea {
                    anchors.fill: parent
                    onPressAndHold: {
                        var target = qsTr("Personalize");
                        appsModel.launch("meego-qml-launcher --opengl --fullscreen --app meego-ux-settings --cmd showPage --cdata \"" + target + "\"");
                    }
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            height: parent.height
            width: drawingArea.cellWidth/4
            color: "yellow"
            opacity: activePager == 10 && listView.currentIndex > 0 ?  0.1 : 0.0
        }
        Rectangle {
            anchors.right: parent.right
            height: parent.height
            width: drawingArea.cellWidth/4
            color: "yellow"
            opacity: activePager == 11 && listView.currentIndex < 9  && listView.currentIndex < listView.count - 1 ?  0.1 : 0.0
        }


        Item {
            id: trash
            anchors.left:  listView.left
            anchors.bottom: listView.bottom
            anchors.bottomMargin: -height/2
            opacity: customizeMode ? 1.0 : 0.0
            property bool active: false
            width: drawingArea.width/8
            height: drawingArea.height/8
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
            Image {
                anchors.centerIn: parent
                scale: parent.active ? 3.0 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 200 }
                }
                source: parent.active ? "image://meegotheme/widgets/apps/home-screen/trash-active" : "image://meegotheme/widgets/apps/home-screen/trash"
            }
        }

        Row {
            id: pager
            anchors.bottom: listView.bottom
            anchors.bottomMargin: -height/2
            anchors.horizontalCenter: listView.horizontalCenter
            spacing: 10
            z: 10
            opacity: listView.model.count > 1 ? 1.0 : 0.0
            Repeater {
                model: listView.model
                Item {
                    property int pageIndex: dpage
                    width: drawingArea.cellWidth/4
                    height: drawingArea.cellHeight/4
                    scale: dpage != listView.currentItem.page && activePager == dpage ? 3.0 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 100 }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "slategray"
                        opacity: 0.5
                    }
                    Text {
                        anchors.fill: parent
                        font.pixelSize: height * 0.75
                        color: "black"
                        text: pageIndex + 1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        smooth: true
                        font.bold:  pageIndex == listView.currentIndex ? true : false
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (customizeMode)
                            {
                                customizeTimer.running = false;
                                customizeTimer.running = true;
                            }

                            listView.currentIndex = pageIndex
                        }
                    }
                }
            }
        }

        Connections {
            target: scene
            onOrientationChanged: {
                listView.relayout();
            }
        }
    }
}
