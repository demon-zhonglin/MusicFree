import { MusicItem as MusicItemModel } from '../../model/MusicItem'
import { MusicItemView } from './MusicItemView'
import { Empty } from '../base/Empty'

/**
 * 音乐列表数据源
 * 实现 IDataSource 接口用于 LazyForEach 懒加载
 */
export class MusicListDataSource implements IDataSource {
  private musicList: MusicItemModel[] = []
  private listeners: DataChangeListener[] = []

  constructor(list: MusicItemModel[] = []) {
    this.musicList = list
  }

  // 获取数据总数
  totalCount(): number {
    return this.musicList.length
  }

  // 获取指定索引的数据
  getData(index: number): MusicItemModel {
    return this.musicList[index]
  }

  // 注册数据变化监听器
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  // 注销数据变化监听器
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  // 更新整个列表
  updateList(newList: MusicItemModel[]): void {
    this.musicList = newList
    this.notifyDataReload()
  }

  // 添加单项
  addItem(item: MusicItemModel): void {
    this.musicList.push(item)
    this.notifyDataAdd(this.musicList.length - 1)
  }

  // 移除单项
  removeItem(index: number): void {
    if (index >= 0 && index < this.musicList.length) {
      this.musicList.splice(index, 1)
      this.notifyDataDelete(index)
    }
  }

  // 通知数据重载
  private notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded()
    })
  }

  // 通知数据添加
  private notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdded(index)
    })
  }

  // 通知数据删除
  private notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDeleted(index)
    })
  }
}

/**
 * 音乐列表组件（使用 LazyForEach 优化）
 */
@Component
export struct MusicList {
  @Prop musicList: MusicItemModel[] = []
  @Prop currentMusicId: string = ''
  @Prop currentPlatform: string = ''
  @Prop showIndex: boolean = false
  @Prop emptyTitle: string = '暂无音乐'
  @Prop emptyDescription: string = ''
  @Prop useLazyForEach: boolean = true  // 是否使用 LazyForEach
  onItemPress?: (music: MusicItemModel, index: number) => void
  onItemMorePress?: (music: MusicItemModel) => void
  
  // 数据源
  private dataSource: MusicListDataSource = new MusicListDataSource()
  @State private dataSourceVersion: number = 0  // 用于触发更新

  aboutToAppear(): void {
    this.dataSource.updateList(this.musicList)
  }

  aboutToUpdate(): void {
    // 当 musicList 变化时更新数据源
    if (this.useLazyForEach) {
      this.dataSource.updateList(this.musicList)
      this.dataSourceVersion++  // 触发重新渲染
    }
  }

  build() {
    if (this.musicList.length === 0) {
      Empty({
        title: this.emptyTitle,
        description: this.emptyDescription
      })
    } else if (this.useLazyForEach && this.musicList.length > 50) {
      // 大数据量使用 LazyForEach
      List() {
        LazyForEach(this.dataSource, (item: MusicItemModel, index: number) => {
          ListItem() {
            MusicItemView({
              music: item,
              isPlaying: item.id === this.currentMusicId && item.platform === this.currentPlatform,
              showIndex: this.showIndex,
              index: index,
              onPress: (music) => {
                this.onItemPress?.(music, index)
              },
              onMorePress: this.onItemMorePress
            })
          }
        }, (item: MusicItemModel) => `${item.platform}@${item.id}`)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.5,
        color: $r('app.color.divider'),
        startMargin: this.showIndex ? 108 : 76,
        endMargin: 16
      })
      .edgeEffect(EdgeEffect.Spring)
      .cachedCount(5)  // 缓存数量，提升滚动性能
    } else {
      // 小数据量使用 ForEach
      List() {
        ForEach(this.musicList, (item: MusicItemModel, index: number) => {
          ListItem() {
            MusicItemView({
              music: item,
              isPlaying: item.id === this.currentMusicId && item.platform === this.currentPlatform,
              showIndex: this.showIndex,
              index: index,
              onPress: (music) => {
                this.onItemPress?.(music, index)
              },
              onMorePress: this.onItemMorePress
            })
          }
        }, (item: MusicItemModel) => `${item.platform}@${item.id}`)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.5,
        color: $r('app.color.divider'),
        startMargin: this.showIndex ? 108 : 76,
        endMargin: 16
      })
      .edgeEffect(EdgeEffect.Spring)
    }
  }
}

/**
 * 带头部的音乐列表组件（使用 LazyForEach 优化）
 */
@Component
export struct MusicListWithHeader {
  @Prop musicList: MusicItemModel[] = []
  @Prop currentMusicId: string = ''
  @Prop currentPlatform: string = ''
  @BuilderParam headerContent?: () => void
  onItemPress?: (music: MusicItemModel, index: number) => void
  onItemMorePress?: (music: MusicItemModel) => void
  onPlayAll?: () => void
  
  // 数据源
  private dataSource: MusicListDataSource = new MusicListDataSource()
  @State private dataSourceVersion: number = 0

  aboutToAppear(): void {
    this.dataSource.updateList(this.musicList)
  }

  aboutToUpdate(): void {
    this.dataSource.updateList(this.musicList)
    this.dataSourceVersion++
  }

  build() {
    List() {
      if (this.headerContent) {
        ListItem() {
          this.headerContent()
        }
      }

      ListItem() {
        Row() {
          Image($r('app.media.ic_play_circle'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.primary'))

          Text(`播放全部 (${this.musicList.length})`)
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .margin({ left: 8 })

          Blank()
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.onPlayAll?.()
        })
      }

      // 大数据量使用 LazyForEach
      if (this.musicList.length > 50) {
        LazyForEach(this.dataSource, (item: MusicItemModel, index: number) => {
          ListItem() {
            MusicItemView({
              music: item,
              isPlaying: item.id === this.currentMusicId && item.platform === this.currentPlatform,
              showIndex: true,
              index: index,
              onPress: (music) => {
                this.onItemPress?.(music, index)
              },
              onMorePress: this.onItemMorePress
            })
          }
        }, (item: MusicItemModel) => `${item.platform}@${item.id}`)
      } else {
        ForEach(this.musicList, (item: MusicItemModel, index: number) => {
          ListItem() {
            MusicItemView({
              music: item,
              isPlaying: item.id === this.currentMusicId && item.platform === this.currentPlatform,
              showIndex: true,
              index: index,
              onPress: (music) => {
                this.onItemPress?.(music, index)
              },
              onMorePress: this.onItemMorePress
            })
          }
        }, (item: MusicItemModel) => `${item.platform}@${item.id}`)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
    .cachedCount(this.musicList.length > 50 ? 5 : 0)
  }
}
