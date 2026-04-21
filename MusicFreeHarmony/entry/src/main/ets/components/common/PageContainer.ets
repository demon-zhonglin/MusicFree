import { MusicBar, MusicBarSpacer } from '../music/MusicBar'
import { AppBar, AppBarOptions } from '../base/AppBar'
import { Empty } from '../base/Empty'
import { RouteConst, EmptyRouteParam } from '../../constants/RouteConst'

/**
 * 页面容器组件
 * 封装通用的页面结构：导航、布局、加载状态、空状态、底部播放栏
 */
@Component
export struct PageContainer {
  // 导航栈
  navPathStack: NavPathStack = new NavPathStack()
  
  // 标题栏配置
  @Prop title: string = ''
  @Prop showBack: boolean = true
  @Prop showAppBar: boolean = true
  onBackPress?: () => void
  
  // 右侧内容构建器
  @BuilderParam rightContent: () => void = () => {}
  
  // 内容构建器
  @BuilderParam content: () => void = () => {}
  
  // 加载状态
  @Prop isLoading: boolean = false
  
  // 空状态
  @Prop isEmpty: boolean = false
  @Prop emptyTitle: string = '暂无数据'
  @Prop emptyDescription: string = ''
  
  // 是否显示底部播放栏
  @Prop showMusicBar: boolean = true
  
  // 点击播放栏回调
  onMusicBarPress?: () => void

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // 标题栏
          if (this.showAppBar) {
            AppBar({
              title: this.title,
              showBack: this.showBack,
              onBackPress: () => {
                if (this.onBackPress) {
                  this.onBackPress()
                } else {
                  this.navPathStack.pop()
                }
              },
              rightContent: () => {
                this.rightContent()
              }
            })
          }

          // 内容区域
          if (this.isLoading) {
            this.LoadingContent()
          } else if (this.isEmpty) {
            Empty({
              title: this.emptyTitle,
              description: this.emptyDescription
            })
            .layoutWeight(1)
          } else {
            this.content()
          }

          // 底部播放栏占位
          if (this.showMusicBar) {
            MusicBarSpacer()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))

        // 底部播放栏
        if (this.showMusicBar) {
          MusicBar({
            onPress: () => {
              if (this.onMusicBarPress) {
                this.onMusicBarPress()
              } else {
                this.navPathStack.pushPathByName(RouteConst.MUSIC_DETAIL, new EmptyRouteParam())
              }
            }
          })
        }
      }
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.navPathStack.pop()
      return true
    })
  }

  @Builder
  LoadingContent() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.primary'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 页面容器选项（用于构建器模式）
 */
export class PageContainerOptions {
  title: string = ''
  showBack: boolean = true
  showAppBar: boolean = true
  showMusicBar: boolean = true
  isLoading: boolean = false
  isEmpty: boolean = false
  emptyTitle: string = '暂无数据'
  emptyDescription: string = ''
  onBackPress?: () => void
  onMusicBarPress?: () => void
  
  static create(): PageContainerOptions {
    return new PageContainerOptions()
  }
  
  withTitle(title: string): PageContainerOptions {
    this.title = title
    return this
  }
  
  withLoading(isLoading: boolean): PageContainerOptions {
    this.isLoading = isLoading
    return this
  }
  
  withEmpty(isEmpty: boolean, title?: string, description?: string): PageContainerOptions {
    this.isEmpty = isEmpty
    if (title) this.emptyTitle = title
    if (description) this.emptyDescription = description
    return this
  }
  
  withoutMusicBar(): PageContainerOptions {
    this.showMusicBar = false
    return this
  }
  
  withoutAppBar(): PageContainerOptions {
    this.showAppBar = false
    return this
  }
}
