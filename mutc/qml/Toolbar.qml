import Qt 4.7

Rectangle {
    SystemPalette { id: activePalette }
    Style { id: style }

    width: parent.width

    border.width: 2
    border.color: style.darkBorderColor

    color: style.backgroundColor

    z: 100

}
