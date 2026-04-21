import { MusicItem } from '../model/MusicItem'
import { PluginManagerVM, getPluginManagerVM } from '../viewmodel/PluginManagerVM'
import { TrackPlayerVM, getTrackPlayerVM } from '../viewmodel/TrackPlayerVM'
import { MusicList } from '../components/music/MusicList'
import { MusicBar, MusicBarSpacer } from '../components/music/MusicBar'
import { ChipGroup } from '../components/base/Chip'
import { Empty } from '../components/base/Empty'
import { RouteConst, EmptyRouteParam, SheetOption } from '../constants/RouteConst'

@Builder
export function SearchBuilder() {
  SearchPage()
}

@Entry
@Component
struct SearchPage {
  @State pluginVM: PluginManagerVM = getPluginManagerVM()
  @State playerVM: TrackPlayerVM = getTrackPlayerVM()
  @State searchText: string = ''
  @State searchResults: Map<string, MusicItem[]> = new Map()
  @State isSearching: boolean = false
  @State selectedPlatformIndex: number = 0
  @State searchHistory: string[] = []
  private navPathStack: NavPathStack = new NavPathStack()

  get platforms(): string[] {
    return ['全部', ...this.pluginVM.searchablePlugins.map(p => p.platform)]
  }

  get currentResults(): MusicItem[] {
    if (this.selectedPlatformIndex === 0) {
      // 全部结果
      const allResults: MusicItem[] = []
      this.searchResults.forEach((items) => {
        allResults.push(...items)
      })
      return allResults
    } else {
      const platform = this.platforms[this.selectedPlatformIndex]
      return this.searchResults.get(platform) ?? []
    }
  }

  aboutToAppear(): void {
    // 加载搜索历史
    // TODO: 从存储加载
  }

  async doSearch(): Promise<void> {
    if (!this.searchText.trim()) return

    this.isSearching = true
    this.searchResults.clear()

    try {
      const results = await this.pluginVM.search(this.searchText.trim())
      this.searchResults = results

      // 添加到搜索历史
      if (!this.searchHistory.includes(this.searchText.trim())) {
        this.searchHistory.unshift(this.searchText.trim())
        if (this.searchHistory.length > 20) {
          this.searchHistory.pop()
        }
      }
    } catch (err) {
      console.error('Search failed:', err)
    } finally {
      this.isSearching = false
    }
  }

  async playMusic(music: MusicItem, index: number): Promise<void> {
    // 获取播放源
    const source = await this.pluginVM.getMediaSource(music)
    if (source?.url) {
      music.url = source.url
      this.playerVM.setPlayList(this.currentResults, index)
      await this.playerVM.play(music)
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // 搜索栏
          Row() {
            Image($r('app.media.ic_back'))
              .width(24)
              .height(24)
              .fillColor($r('app.color.text_primary'))
              .margin({ right: 12 })
              .onClick(() => {
                this.navPathStack.pop()
              })

            TextInput({ placeholder: '搜索音乐、歌手、专辑', text: this.searchText })
              .layoutWeight(1)
              .height(40)
              .borderRadius(20)
              .backgroundColor($r('app.color.chip_background'))
              .padding({ left: 16, right: 16 })
              .onChange((value) => {
                this.searchText = value
              })
              .onSubmit(() => {
                this.doSearch()
              })

            if (this.searchText.length > 0) {
              Text('搜索')
                .fontSize(14)
                .fontColor($r('app.color.primary'))
                .margin({ left: 12 })
                .onClick(() => {
                  this.doSearch()
                })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          if (this.isSearching) {
            // 搜索中
            Column() {
              LoadingProgress()
                .width(48)
                .height(48)
                .color($r('app.color.primary'))

              Text('搜索中...')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 16 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.searchResults.size > 0) {
            // 搜索结果
            Column() {
              // 平台切换
              ChipGroup({
                labels: this.platforms,
                selectedIndex: this.selectedPlatformIndex,
                onSelect: (index) => {
                  this.selectedPlatformIndex = index
                }
              })
              .margin({ top: 8, bottom: 8 })

              // 结果列表
              MusicList({
                musicList: this.currentResults,
                currentMusicId: this.playerVM.currentMusic?.id ?? '',
                currentPlatform: this.playerVM.currentMusic?.platform ?? '',
                emptyTitle: '暂无搜索结果',
                onItemPress: (music, index) => {
                  this.playMusic(music, index)
                },
                onItemMorePress: (music) => {
                  this.showMusicMenu(music)
                }
              })
            }
            .layoutWeight(1)
          } else if (this.searchText.length > 0) {
            // 无结果
            Empty({
              title: '暂无搜索结果',
              description: '换个关键词试试'
            })
            .layoutWeight(1)
          } else {
            // 搜索历史
            Column() {
              if (this.searchHistory.length > 0) {
                Row() {
                  Text('搜索历史')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))

                  Blank()

                  Text('清空')
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                    .onClick(() => {
                      this.searchHistory = []
                    })
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 16, bottom: 8 })

                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.searchHistory, (keyword: string) => {
                    Text(keyword)
                      .fontSize(13)
                      .fontColor($r('app.color.text_primary'))
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .borderRadius(16)
                      .backgroundColor($r('app.color.chip_background'))
                      .margin({ right: 8, bottom: 8 })
                      .onClick(() => {
                        this.searchText = keyword
                        this.doSearch()
                      })
                  })
                }
                .padding({ left: 16, right: 16 })
              }

              // 热门搜索提示
              if (this.pluginVM.searchablePlugins.length === 0) {
                Empty({
                  title: '暂无可用插件',
                  description: '请先安装音乐源插件'
                })
                .margin({ top: 60 })
              }
            }
            .layoutWeight(1)
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
    sheets.push(SheetOption.create('添加到歌单', () => {}))
    sheets.push(SheetOption.create('收藏', () => {}))

    ActionSheet.show({
      title: music.title,
      message: '请选择操作',
      sheets: sheets,
      cancel: () => {}
    })
  }
}
