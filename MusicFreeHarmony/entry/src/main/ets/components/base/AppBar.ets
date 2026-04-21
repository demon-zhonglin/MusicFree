@Component
export struct AppBar {
  @Prop title: string = ''
  @Prop showBack: boolean = true
  @Prop bgColor: ResourceColor = $r('app.color.background')
  onBackPress?: () => void
  @BuilderParam rightContent?: () => void

  build() {
    Row() {
      if (this.showBack) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .fillColor($r('app.color.text_primary'))
          .onClick(() => {
            this.onBackPress?.()
          })
      }

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.rightContent) {
        this.rightContent()
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.bgColor)
  }
}
