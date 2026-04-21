import { MusicItem } from '../model/MusicItem'
import { MusicSheetVM, getMusicSheetVM, RECENT_PLAY_SHEET_ID } from '../viewmodel/MusicSheetVM'
import { TrackPlayerVM, getTrackPlayerVM } from '../viewmodel/TrackPlayerVM'
import { PluginManagerVM, getPluginManagerVM } from '../viewmodel/PluginManagerVM'
import { MusicList } from '../components/music/MusicList'
import { MusicBar, MusicBarSpacer } from '../components/music/MusicBar'
import { AppBar } from '../components/base/AppBar'
import { Empty } from '../components/base/Empty'
import { RouteConst, EmptyRouteParam, SheetOption } from '../constants/RouteConst'

@Builder
export function HistoryBuilder() {
  History()
}

@Entry
@Component
struct History {
  @State sheetVM: MusicSheetVM = getMusicSheetVM()
  @State playerVM: TrackPlayerVM = getTrackPlayerVM()
  @State pluginVM: PluginManagerVM = getPluginManagerVM()
  @State musicList: MusicItem[] = []
  @State isLoading: boolean = true
  private navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.loadHistory()
  }

  async loadHistory(): Promise<void> {
    this.isLoading = true
    const sheet = await this.sheetVM.loadSheet(RECENT_PLAY_SHEET_ID)
    this.musicList = sheet?.musicList ?? []
    this.isLoading = false
  }

  async playMusic(music: MusicItem, index: number): Promise<void> {
    const source = await this.pluginVM.getMediaSource(music)
    if (source?.url) {
      music.url = source.url
    }

    this.playerVM.setPlayList(this.musicList, index)
    await this.playerVM.play(music)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          AppBar({
            title: '播放历史',
            showBack: true,
            onBackPress: () => {
              this.navPathStack.pop()
            },
            rightContent: () => {
              if (this.musicList.length > 0) {
                Text('清空')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .onClick(() => {
                    this.showClearConfirm()
                  })
              }
            }
          })

          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .width(48)
                .height(48)
                .color($r('app.color.primary'))
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.musicList.length === 0) {
            Empty({
              title: '暂无播放历史',
              description: '听几首歌曲试试吧'
            })
            .layoutWeight(1)
          } else {
            MusicList({
              musicList: this.musicList,
              currentMusicId: this.playerVM.currentMusic?.id ?? '',
              currentPlatform: this.playerVM.currentMusic?.platform ?? '',
              onItemPress: (music, index) => {
                this.playMusic(music, index)
              },
              onItemMorePress: (music) => {
                this.showMusicMenu(music)
              }
            })
          }

          MusicBarSpacer()
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))

        MusicBar({
          onPress: () => {
            this.navPathStack.pushPathByName(RouteConst.MUSIC_DETAIL, new EmptyRouteParam())
          }
        })
      }
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.navPathStack.pop()
      return true
    })
  }

  showMusicMenu(music: MusicItem): void {
    const sheets: SheetOption[] = []
    sheets.push(SheetOption.create('下一首播放', () => {
      this.playerVM.addToPlayList(music, true)
    }))
    sheets.push(SheetOption.create('收藏', async () => {
      await this.sheetVM.toggleFavorite(music)
    }))
    sheets.push(SheetOption.create('添加到歌单', () => {}))
    sheets.push(SheetOption.create('从历史中移除', async () => {
      await this.sheetVM.removeMusicFromSheet(RECENT_PLAY_SHEET_ID, music)
      await this.loadHistory()
    }))

    ActionSheet.show({
      title: music.title,
      message: '请选择操作',
      sheets: sheets,
      cancel: () => {}
    })
  }

  showClearConfirm(): void {
    AlertDialog.show({
      title: '清空播放历史',
      message: '确定要清空所有播放历史吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清空',
        fontColor: $r('app.color.error'),
        action: async () => {
          await this.sheetVM.clearRecentPlay()
          this.musicList = []
        }
      }
    })
  }
}
