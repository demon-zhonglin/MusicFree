import { MusicItem as MusicItemModel } from '../../model/MusicItem'
import { MusicImage } from '../base/MusicImage'

@Component
export struct MusicItemView {
  @Prop music: MusicItemModel
  @Prop isPlaying: boolean = false
  @Prop showIndex: boolean = false
  @Prop index: number = 0
  onPress?: (music: MusicItemModel) => void
  onMorePress?: (music: MusicItemModel) => void

  build() {
    Row() {
      if (this.showIndex) {
        Text((this.index + 1).toString())
          .fontSize(14)
          .fontColor(this.isPlaying ? $r('app.color.primary') : $r('app.color.text_hint'))
          .width(32)
          .textAlign(TextAlign.Center)
      }

      MusicImage({ src: this.music.artwork ?? '', imageSize: 48 })

      Column() {
        Text(this.music.title)
          .fontSize(16)
          .fontColor(this.isPlaying ? $r('app.color.primary') : $r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          if (this.music.platform) {
            Text(this.music.platform)
              .fontSize(10)
              .fontColor($r('app.color.text_hint'))
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(2)
              .backgroundColor($r('app.color.chip_background'))
              .margin({ right: 6 })
          }

          Text(this.music.artist ?? '未知艺术家')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Image($r('app.media.ic_more'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_secondary'))
        .padding(4)
        .onClick(() => {
          this.onMorePress?.(this.music)
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.onPress?.(this.music)
    })
  }
}

@Component
export struct MusicItemViewCompact {
  @Prop music: MusicItemModel
  @Prop isPlaying: boolean = false
  onPress?: (music: MusicItemModel) => void

  build() {
    Row() {
      MusicImage({ src: this.music.artwork ?? '', imageSize: 40, radius: 4 })

      Column() {
        Text(this.music.title)
          .fontSize(14)
          .fontColor(this.isPlaying ? $r('app.color.primary') : $r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.music.artist ?? '未知艺术家')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
    }
    .width('100%')
    .height(52)
    .padding({ left: 12, right: 12 })
    .onClick(() => {
      this.onPress?.(this.music)
    })
  }
}
