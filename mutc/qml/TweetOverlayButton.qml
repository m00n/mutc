import Qt 4.7

Button {
    default_color: "#000000"
    width: ListView.view ? ListView.view.model.buttonWidth : 30
    height: 30
    z: 7

    onButtonHovered: {
        ListView.view.currentIndex = VisualItemModel.index
    }
}
