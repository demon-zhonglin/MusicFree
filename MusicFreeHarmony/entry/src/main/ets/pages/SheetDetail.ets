import { MusicSheet } from '../model/MusicSheet'
import { MusicItem } from '../model/MusicItem'
import { MusicSheetVM, getMusicSheetVM } from '../viewmodel/MusicSheetVM'
import { TrackPlayerVM, getTrackPlayerVM } from '../viewmodel/TrackPlayerVM'
import { PluginManagerVM, getPluginManagerVM } from '../viewmodel/PluginManagerVM'
import { MusicListWithHeader } from '../components/music/MusicList'
import { MusicBar, MusicBarSpacer } from '../components/music/MusicBar'
import { MusicImage } from '../components/base/MusicImage'
import { IconButton } from '../components/base/IconButton'
import { Empty } from '../components/base/Empty'
import { RouteConst, EmptyRouteParam, SheetOption } from '../constants/RouteConst'

@Builder
export function SheetDetailBuilder() {
  SheetDetail()
}

@Entry
@Component
struct SheetDetail {
  @State sheetVM: MusicSheetVM = getMusicSheetVM()
  @State playerVM: TrackPlayerVM = getTrackPlayerVM()
  @State pluginVM: PluginManagerVM = getPluginManagerVM()
  @State sheet: MusicSheet | null = null
  @State isLoading: boolean = true
  private sheetId: string = ''
  private navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.loadSheet()
  }

  async loadSheet(): Promise<void> {
    this.isLoading = true
    this.sheet = await this.sheetVM.loadSheet(this.sheetId)
    this.isLoading = false
  }

  async playMusic(music: MusicItem, index: number): Promise<void> {
    // 获取播放源
    const source = await this.pluginVM.getMediaSource(music)
    if (source?.url) {
      music.url = source.url
    }

    // 设置播放列表并播放
    this.playerVM.setPlayList(this.sheet?.musicList ?? [], index)
    await this.playerVM.play(music)

    // 添加到最近播放
    await this.sheetVM.addToRecentPlay(music)
  }

  async playAll(): Promise<void> {
    if (this.sheet?.musicList && this.sheet.musicList.length > 0) {
      await this.playMusic(this.sheet.musicList[0], 0)
    }
  }

  @Builder
  SheetHeader() {
    Column() {
      Row() {
        MusicImage({
          src: this.sheet !== null ? this.sheet.coverImg : '',
          imageSize: 120,
          radius: 12
        })
        .shadow({
          radius: 16,
          color: '#20000000',
          offsetY: 4
        })

        Column() {
          Text(this.sheet?.title ?? '')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.sheet?.description) {
            Text(this.sheet.description)
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 8 })
          }

          Text(`${this.sheet?.musicList?.length ?? 0} 首歌曲`)
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      // 操作按钮
      Row({ space: 12 }) {
        Button('播放全部')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.primary'))
          .height(36)
          .layoutWeight(1)
          .onClick(() => {
            this.playAll()
          })

        Button('随机播放')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor($r('app.color.primary'))
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor($r('app.color.primary'))
          .height(36)
          .layoutWeight(1)
          .onClick(() => {
            // TODO: 随机播放
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // 顶部栏
          Row() {
            IconButton({
              icon: $r('app.media.ic_back'),
              iconSize: 24,
              onButtonClick: () => {
                this.navPathStack.pop()
              }
            })

            Blank()

            IconButton({
              icon: $r('app.media.ic_more'),
              iconSize: 24,
              onButtonClick: () => {
                this.showSheetMenu()
              }
            })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 8 })

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
          } else if (this.sheet) {
            if ((this.sheet.musicList?.length ?? 0) === 0) {
              Column() {
                this.SheetHeader()

                Empty({
                  title: '歌单是空的',
                  description: '快去添加一些歌曲吧'
                })
                .layoutWeight(1)
              }
            } else {
              MusicListWithHeader({
                musicList: this.sheet.musicList ?? [],
                currentMusicId: this.playerVM.currentMusic?.id ?? '',
                currentPlatform: this.playerVM.currentMusic?.platform ?? '',
                headerContent: () => {
                  this.SheetHeader()
                },
                onItemPress: (music, index) => {
                  this.playMusic(music, index)
                },
                onItemMorePress: (music) => {
                  this.showMusicMenu(music)
                },
                onPlayAll: () => {
                  this.playAll()
                }
              })
            }
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

  showSheetMenu(): void {
    const sheets: SheetOption[] = []
    sheets.push(SheetOption.create('编辑歌单', () => this.showEditSheet()))

    // 非系统歌单才能删除
    if (this.sheetId !== 'favorite' && this.sheetId !== 'recent_play') {
      sheets.push(SheetOption.create('删除歌单', () => this.showDeleteConfirm()))
    }

    sheets.push(SheetOption.create('清空歌单', () => this.showClearConfirm()))

    ActionSheet.show({
      title: this.sheet !== null ? this.sheet.title : '歌单操作',
      message: '请选择操作',
      sheets: sheets,
      cancel: () => {}
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
    sheets.push(SheetOption.create('添加到其他歌单', () => {}))
    sheets.push(SheetOption.create('从歌单中移除', async () => {
      await this.sheetVM.removeMusicFromSheet(this.sheetId, music)
      await this.loadSheet()
    }))

    ActionSheet.show({
      title: music.title,
      message: '请选择操作',
      sheets: sheets,
      cancel: () => {}
    })
  }

  showEditSheet(): void {
    // TODO: 编辑歌单弹窗
  }

  showDeleteConfirm(): void {
    AlertDialog.show({
      title: '删除歌单',
      message: `确定要删除歌单「${this.sheet?.title}」吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('app.color.error'),
        action: async () => {
          await this.sheetVM.deleteSheet(this.sheetId)
          this.navPathStack.pop()
        }
      }
    })
  }

  showClearConfirm(): void {
    AlertDialog.show({
      title: '清空歌单',
      message: '确定要清空歌单中的所有歌曲吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清空',
        fontColor: $r('app.color.error'),
        action: async () => {
          await this.sheetVM.clearSheet(this.sheetId)
          await this.loadSheet()
        }
      }
    })
  }
}
