@Component
export struct Empty {
  @Prop icon: Resource = $r('app.media.ic_empty')
  @Prop title: string = '暂无内容'
  @Prop description: string = ''
  @Prop iconSize: number = 80

  build() {
    Column() {
      Image(this.icon)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor($r('app.color.text_hint'))

      Text(this.title)
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 16 })

      if (this.description && this.description.length > 0) {
        Text(this.description)
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct EmptyWithAction {
  @Prop icon: Resource = $r('app.media.ic_empty')
  @Prop title: string = '暂无内容'
  @Prop description: string = ''
  @Prop actionText: string = ''
  onAction?: () => void

  build() {
    Column() {
      Empty({
        icon: this.icon,
        title: this.title,
        description: this.description
      })

      if (this.actionText && this.actionText.length > 0) {
        Button(this.actionText)
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.primary'))
          .padding({ left: 24, right: 24, top: 10, bottom: 10 })
          .margin({ top: 16 })
          .onClick(() => {
            this.onAction?.()
          })
      }
    }
  }
}
