import { MusicSheet } from '../model/MusicSheet'
import { MusicSheetVM, getMusicSheetVM } from '../viewmodel/MusicSheetVM'
import { TrackPlayerVM, getTrackPlayerVM } from '../viewmodel/TrackPlayerVM'
import { MusicBar, MusicBarSpacer } from '../components/music/MusicBar'
import { MusicImage } from '../components/base/MusicImage'
import { RouteConst, EmptyRouteParam, SheetDetailRouteParam } from '../constants/RouteConst'

@Builder
export function HomeBuilder() {
  Home()
}

@Entry
@Component
struct Home {
  @State playerVM: TrackPlayerVM = getTrackPlayerVM()
  @State sheetVM: MusicSheetVM = getMusicSheetVM()
  @State isRefreshing: boolean = false
  private navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.loadData()
  }

  async loadData(): Promise<void> {
    this.isRefreshing = true
    await this.sheetVM.refreshSheets()
    this.isRefreshing = false
  }

  @Builder
  QuickEntry(icon: Resource, title: string, badge: number = 0, onClick: () => void) {
    Column() {
      Stack() {
        Image(icon)
          .width(28)
          .height(28)
          .fillColor($r('app.color.primary'))

        if (badge > 0) {
          Text(badge > 99 ? '99+' : badge.toString())
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.error'))
            .borderRadius(8)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .position({ x: '60%', y: 0 })
        }
      }
      .width(40)
      .height(40)

      Text(title)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 6 })
    }
    .width('25%')
    .padding({ top: 12, bottom: 12 })
    .onClick(onClick)
  }

  @Builder
  SheetItem(sheet: MusicSheet, musicCount: number) {
    Row() {
      MusicImage({ src: sheet.coverImg, imageSize: 56, radius: 8 })

      Column() {
        Text(sheet.title)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${musicCount} 首`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Image($r('app.media.ic_arrow_right'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_hint'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => {
      this.navPathStack.pushPathByName(RouteConst.LOCAL_SHEET_DETAIL, SheetDetailRouteParam.create(sheet.id))
    })
  }

  @Builder
  SectionHeader(title: string, showAdd: boolean = false, onAdd?: () => void) {
    Row() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Blank()

      if (showAdd) {
        Image($r('app.media.ic_add'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_secondary'))
          .onClick(() => {
            if (onAdd !== undefined) {
              onAdd()
            }
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  build() {
    Navigation(this.navPathStack) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // 顶部栏
          Row() {
            Text('MusicFree')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary'))

            Blank()

            Image($r('app.media.ic_search'))
              .width(24)
              .height(24)
              .fillColor($r('app.color.text_primary'))
              .margin({ right: 16 })
              .onClick(() => {
                this.navPathStack.pushPathByName(RouteConst.SEARCH, new EmptyRouteParam())
              })

            Image($r('app.media.ic_settings'))
              .width(24)
              .height(24)
              .fillColor($r('app.color.text_primary'))
              .onClick(() => {
                this.navPathStack.pushPathByName(RouteConst.SETTING, new EmptyRouteParam())
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

          // 下拉刷新列表
          Refresh({ refreshing: $$this.isRefreshing }) {
            List() {
              // 快捷入口
              ListItem() {
                Row() {
                  this.QuickEntry($r('app.media.ic_favorite'), '我喜欢', this.sheetVM.favoriteCount, () => {
                    this.navPathStack.pushPathByName(RouteConst.LOCAL_SHEET_DETAIL, SheetDetailRouteParam.create('favorite'))
                  })
                  this.QuickEntry($r('app.media.ic_history'), '最近播放', this.sheetVM.recentPlayCount, () => {
                    this.navPathStack.pushPathByName(RouteConst.HISTORY, new EmptyRouteParam())
                  })
                  this.QuickEntry($r('app.media.ic_local_music'), '本地音乐', 0, () => {
                    this.navPathStack.pushPathByName(RouteConst.LOCAL_MUSIC, new EmptyRouteParam())
                  })
                  this.QuickEntry($r('app.media.ic_download'), '下载管理', 0, () => {
                    this.navPathStack.pushPathByName(RouteConst.DOWNLOADING, new EmptyRouteParam())
                  })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceAround)
                .backgroundColor($r('app.color.surface'))
                .borderRadius(12)
                .margin({ left: 16, right: 16, top: 8, bottom: 8 })
              }

              // 发现入口
              ListItem() {
                Row() {
                  this.QuickEntry($r('app.media.ic_ranking'), '排行榜', 0, () => {
                    this.navPathStack.pushPathByName(RouteConst.TOP_LIST, new EmptyRouteParam())
                  })
                  this.QuickEntry($r('app.media.ic_recommend'), '推荐歌单', 0, () => {
                    this.navPathStack.pushPathByName(RouteConst.RECOMMEND_SHEETS, new EmptyRouteParam())
                  })
                  this.QuickEntry($r('app.media.ic_plugin'), '插件管理', 0, () => {
                    this.navPathStack.pushPathByName('PluginManager', new EmptyRouteParam())
                  })
                  this.QuickEntry($r('app.media.ic_more_horiz'), '更多', 0, () => {
                    // TODO: 更多功能
                  })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceAround)
                .backgroundColor($r('app.color.surface'))
                .borderRadius(12)
                .margin({ left: 16, right: 16, bottom: 8 })
              }

              // 我的歌单标题
              ListItem() {
                this.SectionHeader('我的歌单', true, () => {
                  this.showCreateSheetDialog()
                })
              }

              // 歌单列表
              ForEach(this.sheetVM.userSheets, (sheet: MusicSheet) => {
                ListItem() {
                  this.SheetItem(sheet, sheet.musicList.length)
                }
              }, (sheet: MusicSheet) => sheet.id)

              // 底部占位
              ListItem() {
                MusicBarSpacer()
              }
            }
            .width('100%')
            .layoutWeight(1)
            .edgeEffect(EdgeEffect.Spring)
          }
          .onRefreshing(() => {
            this.loadData()
          })
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))

        // 底部播放栏
        MusicBar({
          onPress: () => {
            this.navPathStack.pushPathByName(RouteConst.MUSIC_DETAIL, new EmptyRouteParam())
          }
        })
      }
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }

  showCreateSheetDialog(): void {
    AlertDialog.show({
      title: '新建歌单',
      message: '请输入歌单名称',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '创建',
        action: () => {
          // TODO: 实现创建歌单
        }
      }
    })
  }
}