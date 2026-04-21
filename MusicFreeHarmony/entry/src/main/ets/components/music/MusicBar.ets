import { MusicImage } from '../base/MusicImage'
import { IconButton } from '../base/IconButton'
import { TrackPlayerVM, getTrackPlayerVM } from '../../viewmodel/TrackPlayerVM'

@Component
export struct MusicBar {
  @State playerVM: TrackPlayerVM = getTrackPlayerVM()
  onPress?: () => void

  build() {
    if (this.playerVM.currentMusic) {
      Column() {
        // 进度条
        Progress({ value: this.playerVM.progressPercent, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color($r('app.color.primary'))
          .backgroundColor($r('app.color.divider'))

        Row() {
          MusicImage({
            src: this.playerVM.currentMusic !== null ? this.playerVM.currentMusic.artwork : '',
            imageSize: 48,
            radius: 8
          })

          Column() {
            Text(this.playerVM.currentMusic?.title ?? '')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.playerVM.currentMusic?.artist ?? '未知艺术家')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })

          if (this.playerVM.isLoading) {
            LoadingProgress()
              .width(28)
              .height(28)
              .color($r('app.color.primary'))
          } else {
            IconButton({
              icon: this.playerVM.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'),
              iconSize: 28,
              onButtonClick: () => {
                this.playerVM.togglePlay()
              }
            })
          }

          IconButton({
            icon: $r('app.media.ic_skip_next'),
            iconSize: 24,
            onButtonClick: () => {
              this.playerVM.skipToNext()
            }
          })
          .margin({ left: 4 })

          IconButton({
            icon: $r('app.media.ic_playlist'),
            iconSize: 22,
            onButtonClick: () => {
              // TODO: 显示播放列表
            }
          })
          .margin({ left: 4 })
        }
        .width('100%')
        .height(62)
        .padding({ left: 12, right: 8 })
      }
      .width('100%')
      .backgroundColor($r('app.color.surface'))
      .shadow({
        radius: 8,
        color: '#1A000000',
        offsetY: -2
      })
      .onClick(() => {
        this.onPress?.()
      })
    }
  }
}

@Component
export struct MusicBarSpacer {
  @State playerVM: TrackPlayerVM = getTrackPlayerVM()

  build() {
    if (this.playerVM.currentMusic) {
      // 占位，防止内容被底部播放栏遮挡
      Row()
        .width('100%')
        .height(64)
    }
  }
}
