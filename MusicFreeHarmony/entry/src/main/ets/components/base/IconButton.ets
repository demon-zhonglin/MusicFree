@Component
export struct IconButton {
  @Prop icon: Resource
  @Prop iconSize: number = 24
  @Prop color: ResourceColor = $r('app.color.text_primary')
  @Prop buttonPadding: number = 8
  @Prop isEnabled: boolean = true
  onButtonClick?: () => void

  build() {
    Button({ type: ButtonType.Circle }) {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.isEnabled ? this.color : $r('app.color.text_disabled'))
    }
    .width(this.iconSize + this.buttonPadding * 2)
    .height(this.iconSize + this.buttonPadding * 2)
    .backgroundColor(Color.Transparent)
    .enabled(this.isEnabled)
    .onClick(() => {
      if (this.isEnabled) {
        this.onButtonClick?.()
      }
    })
  }
}

@Component
export struct IconButtonFilled {
  @Prop icon: Resource
  @Prop iconSize: number = 24
  @Prop iconColor: ResourceColor = Color.White
  @Prop bgColor: ResourceColor = $r('app.color.primary')
  @Prop buttonPadding: number = 12
  @Prop isEnabled: boolean = true
  onButtonClick?: () => void

  build() {
    Button({ type: ButtonType.Circle }) {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.iconColor)
    }
    .width(this.iconSize + this.buttonPadding * 2)
    .height(this.iconSize + this.buttonPadding * 2)
    .backgroundColor(this.isEnabled ? this.bgColor : $r('app.color.disabled'))
    .enabled(this.isEnabled)
    .onClick(() => {
      if (this.isEnabled) {
        this.onButtonClick?.()
      }
    })
  }
}