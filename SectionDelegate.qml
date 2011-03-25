/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7

Rectangle {
    color: "slategray"
    property alias text: label.text
    Text {
        id: label
        anchors.fill: parent
        elide: Text.ElideRight
        color: "white"
        font.pixelSize: height - height/10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
