@Component
export struct Chip {
  @Prop label: string = ''
  @Prop selected: boolean = false
  @Prop icon?: Resource
  onChipClick?: () => void

  build() {
    Row() {
      if (this.icon) {
        Image(this.icon)
          .width(16)
          .height(16)
          .fillColor(this.selected ? Color.White : $r('app.color.text_primary'))
          .margin({ right: 4 })
      }

      Text(this.label)
        .fontSize(13)
        .fontColor(this.selected ? Color.White : $r('app.color.text_primary'))
    }
    .height(32)
    .padding({ left: 12, right: 12 })
    .borderRadius(16)
    .backgroundColor(this.selected ? $r('app.color.primary') : $r('app.color.chip_background'))
    .onClick(() => {
      this.onChipClick?.()
    })
  }
}

@Component
export struct ChipGroup {
  @Prop labels: string[] = []
  @Prop @Watch('onSelectedChange') selectedIndex: number = 0
  onSelect?: (index: number, label: string) => void

  onSelectedChange() {
    // 选择变化时的处理
  }

  build() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.labels, (label: string, index: number) => {
          Chip({
            label: label,
            selected: index === this.selectedIndex,
            onChipClick: () => {
              this.onSelect?.(index, label)
            }
          })
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
