/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.1
import QtQuick.Window 2.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

import org.kde.taskmanager 0.1 as TaskManager

import org.kde.latte 0.1 as Latte

Item{
    id: manager

    anchors.fill: parent

    property QtObject window

    property bool debugMagager: false

    property bool inStartup: root.inStartup
    property bool normalState : false  // this is being set from updateMaskArea
    property bool previousNormalState : false // this is only for debugging purposes

    property int animationSpeed: root.durationTime * 1.2 * units.longDuration
    property int length: root.isVertical ?  Screen.height : Screen.width   //screenGeometry.height : screenGeometry.width

    //it is used in order to not break the calculations for the thickness placement
    //especially in automatic icon sizes calculations
    property real iconMarginOriginal: 0.12*plasmoid.configuration.iconSize
    property int statesLineSizeOriginal: root.nowDock ? Math.ceil( plasmoid.configuration.iconSize/13 ) : 0

    property int thicknessAutoHidden: 2
    property int thicknessMid: root.statesLineSize + (1 + (0.65 * (root.zoomFactor-1)))*(root.iconSize+root.iconMargin) //needed in some animations
    property int thicknessNormal: Math.max(root.statesLineSize + root.iconSize + root.iconMargin + root.shadowsSize + 1, root.realPanelSize)
    property int thicknessZoom: root.statesLineSize + ((root.iconSize+root.iconMargin) * root.zoomFactor) + 2
    //it is used to keep thickness solid e.g. when iconSize changes from auto functions
    property int thicknessMidOriginal: statesLineSizeOriginal + (1 + (0.65 * (root.zoomFactor-1)))*(plasmoid.configuration.iconSize+iconMarginOriginal) //needed in some animations
    property int thicknessNormalOriginal: Math.max(thicknessNormalOriginalValue, root.realPanelSize)
    property int thicknessNormalOriginalValue: statesLineSizeOriginal + plasmoid.configuration.iconSize + iconMarginOriginal + root.shadowsSize + 1
    property int thicknessZoomOriginal: Math.max(statesLineSizeOriginal + ((plasmoid.configuration.iconSize+iconMarginOriginal) * root.zoomFactor) + root.shadowsSize + 2,
                                                 root.realPanelSize+editModeVisual.shadowSize)

    Binding{
        target: dock
        property:"maxThickness"
        when: dock
        value: thicknessZoomOriginal
    }

    Binding{
        target: dock
        property:"normalThickness"
        when: dock
        value: thicknessNormalOriginal
    }

    onInStartupChanged: {
        if (!inStartup) {
            delayAnimationTimer.start();
        }
    }

    onNormalStateChanged: {
        if (normalState) {
            root.updateAutomaticIconSize();
        }
    }

    onThicknessZoomOriginalChanged: updateMaskArea();

    function slotContainsMouseChanged() {
        if(dock.visibility.containsMouse) {
            if (delayerTimer.running) {
                delayerTimer.stop();
            }

            updateMaskArea();
        } else {
            // initialize the zoom
            delayerTimer.start();
        }
    }

    function slotMustBeShown() {
        //  console.log("show...");
        slidingAnimationAutoHiddenIn.init();
    }

    function slotMustBeHide() {
        // console.log("hide....");
        if(!dock.visibility.blockHiding && !dock.visibility.containsMouse && windowSystem.compositingActive) {
            slidingAnimationAutoHiddenOut.init();
        }
    }

    ///test maskArea
    function updateMaskArea() {
        if (!dock) {
            return;
        }

        var localX = 0;
        var localY = 0;

        normalState = ((root.animationsNeedBothAxis === 0) && (root.animationsNeedLength === 0))
                || !windowSystem.compositingActive;

        // debug maskArea criteria
        if (debugMagager) {
            console.log(root.animationsNeedBothAxis + ", " + root.animationsNeedLength + ", " +
                        root.animationsNeedThickness + ", " + dock.visibility.isHidden);

            if (previousNormalState !== normalState) {
                console.log("normal state changed to:" + normalState);
                previousNormalState = normalState;
            }
        }

        var tempLength = root.isHorizontal ? width : height;
        var tempThickness = root.isHorizontal ? height : width;

        var space = root.useThemePanel ? (plasmoid.configuration.panelPosition === Latte.Dock.Justify) ?
                                             2*root.panelEdgeSpacing + 2*root.shadowsSize : root.panelEdgeSpacing + 2*root.shadowsSize : 2;

        if (normalState) {
            //console.log("entered normal state...");
            //count panel length
            if(root.isHorizontal) {
                tempLength = plasmoid.configuration.panelPosition === Latte.Dock.Justify ?
                            layoutsContainer.width + space : mainLayout.width + space;
            } else {
                tempLength = plasmoid.configuration.panelPosition === Latte.Dock.Justify ?
                            layoutsContainer.height + space : mainLayout.height + space;
            }

            tempThickness = thicknessNormal;

            if (root.animationsNeedThickness > 0) {
                tempThickness = windowSystem.compositingActive ? thicknessMidOriginal : thicknessNormalOriginal;
            }

            if (dock.visibility.isHidden && !slidingAnimationAutoHiddenOut.running ) {
                tempThickness = windowSystem.compositingActive ? thicknessAutoHidden : thicknessNormalOriginal;
            }

            //configure x,y based on plasmoid position and root.panelAlignment(Alignment)
            if ((plasmoid.location === PlasmaCore.Types.BottomEdge) || (plasmoid.location === PlasmaCore.Types.TopEdge)) {
                if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
                    localY = dock.height - tempThickness;
                } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
                    localY = 0;
                }

                if (plasmoid.configuration.panelPosition === Latte.Dock.Justify) {
                    localX = (dock.width/2) - tempLength/2;
                } else if (root.panelAlignment === Latte.Dock.Left) {
                    localX = 0;
                } else if (root.panelAlignment === Latte.Dock.Center) {
                    localX = (dock.width/2) - tempLength/2;
                } else if (root.panelAlignment === Latte.Dock.Right) {
                    localX = dock.width - mainLayout.width - (space/2);
                }
            } else if ((plasmoid.location === PlasmaCore.Types.LeftEdge) || (plasmoid.location === PlasmaCore.Types.RightEdge)){
                if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
                    localX = 0;
                } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                    localX = dock.width - tempThickness;
                }

                if (plasmoid.configuration.panelPosition === Latte.Dock.Justify) {
                    localY = (dock.height/2) - tempLength/2;
                } else if (root.panelAlignment === Latte.Dock.Top) {
                    localY = 0;
                } else if (root.panelAlignment === Latte.Dock.Center) {
                    localY = (dock.height/2) - tempLength/2;
                } else if (root.panelAlignment === Latte.Dock.Bottom) {
                    localY = dock.height - mainLayout.height - (space/2);
                }
            }
        } else {
            if(root.isHorizontal)
                tempLength = Screen.width; //screenGeometry.width;
            else
                tempLength = Screen.height; //screenGeometry.height;

            //grow only on length and not thickness
            if(root.animationsNeedLength>0 && root.animationsNeedBothAxis === 0) {

                //this is used to fix a bug with shadow showing when the animation of edit mode
                //is triggered
                var editModeThickness = editModeVisual.editAnimationEnded ? thicknessNormalOriginal + editModeVisual.shadowSize :
                                                                            thicknessNormalOriginal

                tempThickness = root.editMode ? editModeThickness : thicknessNormalOriginal;

                if (dock.visibility.isHidden && !slidingAnimationAutoHiddenOut.running ) {
                    tempThickness = windowSystem.compositingActive ? thicknessAutoHidden : thicknessNormalOriginal;
                } else if (root.animationsNeedThickness > 0) {
                    tempThickness = thicknessMidOriginal;
                }

                //configure the x,y position based on thickness
                if(plasmoid.location === PlasmaCore.Types.RightEdge)
                    localX = dock.width - tempThickness;
                else if(plasmoid.location === PlasmaCore.Types.BottomEdge)
                    localY = dock.height - tempThickness;
            } else{
                //use all thickness space
                if (dock.visibility.isHidden && !slidingAnimationAutoHiddenOut.running ) {
                    tempThickness = windowSystem.compositingActive ? thicknessAutoHidden : thicknessNormalOriginal;
                } else {
                    tempThickness = thicknessZoomOriginal;
                }
            }
        }
        var maskArea = dock.maskArea;

        var maskLength = maskArea.width; //in Horizontal
        if (root.isVertical) {
            maskLength = maskArea.height;
        }

        var maskThickness = maskArea.height; //in Horizontal
        if (root.isVertical) {
            maskThickness = maskArea.width;
        }

        // console.log("Not updating mask...");
        if( maskArea.x !== localX || maskArea.y !== localY
                || maskLength !== tempLength || maskThickness !== tempThickness) {

            // console.log("Updating mask...");
            var newMaskArea = Qt.rect(-1,-1,0,0);
            newMaskArea.x = localX;
            newMaskArea.y = localY;

            if (isHorizontal) {
                newMaskArea.width = tempLength;
                newMaskArea.height = tempThickness;
            } else {
                newMaskArea.width = tempThickness;
                newMaskArea.height = tempLength;
            }

            dock.maskArea = newMaskArea;

            //console.log("update mask area:"+newMaskArea);
            if(normalState && !dock.visibility.isHidden){
                //the shadows size must be removed from the maskArea
                //before updating the localDockGeometry

                var shadow = root.shadowsSize;

                if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
                    newMaskArea.width = newMaskArea.width - shadow - 1;
                } else {
                    newMaskArea.height = newMaskArea.height - shadow - 1;
                }

                if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
                    newMaskArea.y = newMaskArea.y + shadow;
                } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
                    newMaskArea.x = newMaskArea.x + shadow;
                }

                dock.setLocalDockGeometry(newMaskArea);
                //  console.log("update dock geometry:"+newMaskArea);
            }
        }
    }

    Loader{
        anchors.fill: parent
        active: root.debugMode

        sourceComponent: Item{
            anchors.fill:parent

            Rectangle{
                id: windowBackground
                anchors.fill: parent
                border.color: "red"
                border.width: 1
                color: "transparent"
            }

            Rectangle{
                x: dock ? dock.maskArea.x : -1
                y: dock ? dock.maskArea.y : -1
                height: dock ? dock.maskArea.height : 0
                width: dock ? dock.maskArea.width : 0

                border.color: "green"
                border.width: 1
                color: "transparent"
            }
        }
    }

    /***Hiding/Showing Animations*****/

    //////////////// Animations - Slide In - Out
    SequentialAnimation{
        id: slidingAnimationAutoHiddenOut

        ScriptAction{
            script: dock.visibility.isHidden = true;
        }

        PropertyAnimation {
            target: layoutsContainer
            property: root.isVertical ? "x" : "y"
            to: ((plasmoid.location===PlasmaCore.Types.LeftEdge)||(plasmoid.location===PlasmaCore.Types.TopEdge)) ? -thicknessNormal : thicknessNormal
            duration: manager.animationSpeed
            easing.type: Easing.OutQuad
        }

        onStarted: {
            if (manager.debugMagager) {
                console.log("hiding animation started...");
            }
        }

        onStopped: {
            if (manager.debugMagager) {
                console.log("hiding animation ended...");
            }

            updateMaskArea();
        }

        function init() {
            if (!dock.visibility.blockHiding)
                start();
        }
    }

    SequentialAnimation{
        id: slidingAnimationAutoHiddenIn

        PropertyAnimation {
            target: layoutsContainer
            property: root.isVertical ? "x" : "y"
            to: 0
            duration: manager.animationSpeed
            easing.type: Easing.OutQuad
        }

        onStarted: {
            if (manager.debugMagager) {
                console.log("showing animation started...");
            }
        }

        onStopped: {
            if (manager.debugMagager) {
                console.log("showing animation ended...");
            }
        }

        function init() {
            if (!dock.visibility.blockHiding)
                dock.visibility.isHidden = false;

            updateMaskArea();

            if (slidingAnimationAutoHiddenOut.running) {
                slidingAnimationAutoHiddenOut.stop();
            }

            start();
        }
    }

    ///////////// External Connections //////
    TaskManager.ActivityInfo {
        onCurrentActivityChanged: {
            dock.visibility.disableHiding = true;

            if (dock.visibility.isHidden) {
                dock.visibility.mustBeShown();
            }
        }
    }

    ////////////// Timers //////
    //Timer to delay onLeave event
    Timer {
        id: delayerTimer
        interval: 400
        onTriggered: {
            root.clearZoom();
            if (root.nowDock) {
                nowDock.clearZoom();
            }
        }
    }

    //Timer to delay onLeave event
    Timer {
        id: delayAnimationTimer
        interval: manager.inStartup ? 1000 : 500
        onTriggered: {
            layoutsContainer.opacity = 1;
            if (dock.visibility.mode !== Latte.Dock.AutoHide) {
                slidingAnimationAutoHiddenIn.init();
            }
        }
    }

}
