/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1

// TODO: As soon as we have real hardware then stop wrapping the
//       window in the temporary outershell
Window {
    id: scene
    anchors.centerIn: parent
    showtoolbar: false
    fullscreen: true
    fullContent: true

    // Lock the orientation in LeftUp
    orientationLocked: true
    orientation: qApp.preferredPortraitOrientation
    property bool locked: false

    Component.onCompleted: console.log("XXX theme name: " + theme_name);
    Item {
        id: deviceScreen
        parent: scene.content
        x: 0
        y: 0
        width: parent.width
        height: parent.height + parseInt(theme_statusBarHeight)

        Rectangle {
            id: background
            anchors.fill: parent
            color: "black"
            property variant backgroundImage: null
            BackgroundModel {
                id: backgroundModel
                Component.onCompleted: {
                    background.backgroundImage = backgroundImageComponent.createObject(background);
                }
                onActiveWallpaperChanged: {
                    background.backgroundImage.destroy();
                    background.backgroundImage = backgroundImageComponent.createObject(background);       
                }
            }
            Component {
                id: backgroundImageComponent
                Image {
                    anchors.fill: parent
                    asynchronous: true
                    sourceSize.height: height
                    source: backgroundModel.activeWallpaper
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }

        StatusBar {
            anchors.top: parent.top
            width: parent.width
            height: theme_statusBarHeight
            active: scene.foreground
            backgroundOpacity: theme_panelStatusBarOpacity
        }

        MainContent {
            id: gridContent
            anchors.top: parent.top
            anchors.topMargin: theme_statusBarHeight
            width: parent.width
            height: parent.height
        }
    }
}

