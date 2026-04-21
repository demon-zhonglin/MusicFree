import { AppBar } from '../components/base/AppBar'
import { storageUtil } from '../utils/StorageUtil'
import { EmptyRouteParam, SheetOption } from '../constants/RouteConst'

class SettingItem {
  title: string = ''
  subtitle: string = ''
  icon: Resource | null = null
  showArrow: boolean = true
  showSwitch: boolean = false
  switchValue: boolean = false
  onClick: (() => void) | null = null
  onSwitchChange: ((value: boolean) => void) | null = null

  static create(title: string): SettingItem {
    const item = new SettingItem()
    item.title = title
    return item
  }

  setSubtitle(subtitle: string): SettingItem {
    this.subtitle = subtitle
    return this
  }

  setIcon(icon: Resource): SettingItem {
    this.icon = icon
    return this
  }

  setShowArrow(showArrow: boolean): SettingItem {
    this.showArrow = showArrow
    return this
  }

  setShowSwitch(showSwitch: boolean): SettingItem {
    this.showSwitch = showSwitch
    return this
  }

  setSwitchValue(switchValue: boolean): SettingItem {
    this.switchValue = switchValue
    return this
  }

  setOnClick(onClick: () => void): SettingItem {
    this.onClick = onClick
    return this
  }

  setOnSwitchChange(onSwitchChange: (value: boolean) => void): SettingItem {
    this.onSwitchChange = onSwitchChange
    return this
  }
}

@Builder
export function SettingBuilder() {
  Setting()
}

@Entry
@Component
struct Setting {
  @State darkMode: boolean = false
  @State autoPlay: boolean = true
  @State wifiOnly: boolean = false
  @State showLyric: boolean = true
  @State cacheSize: string = '计算中...'
  private navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.loadSettings()
    this.calculateCacheSize()
  }

  async loadSettings(): Promise<void> {
    this.darkMode = await storageUtil.get<boolean>('darkMode', false) ?? false
    this.autoPlay = await storageUtil.get<boolean>('autoPlay', true) ?? true
    this.wifiOnly = await storageUtil.get<boolean>('wifiOnly', false) ?? false
    this.showLyric = await storageUtil.get<boolean>('showLyric', true) ?? true
  }

  async calculateCacheSize(): Promise<void> {
    // TODO: 计算实际缓存大小
    this.cacheSize = '128.5 MB'
  }

  getPlaySettings(): SettingItem[] {
    const items: SettingItem[] = []

    const autoPlayItem = SettingItem.create('自动播放')
      .setSubtitle('进入歌单后自动播放')
      .setShowSwitch(true)
      .setSwitchValue(this.autoPlay)
      .setOnSwitchChange(async (value: boolean) => {
        this.autoPlay = value
        await storageUtil.set('autoPlay', value)
      })
    items.push(autoPlayItem)

    const lyricItem = SettingItem.create('锁屏歌词')
      .setSubtitle('在锁屏界面显示歌词')
      .setShowSwitch(true)
      .setSwitchValue(this.showLyric)
      .setOnSwitchChange(async (value: boolean) => {
        this.showLyric = value
        await storageUtil.set('showLyric', value)
      })
    items.push(lyricItem)

    return items
  }

  getDownloadSettings(): SettingItem[] {
    const items: SettingItem[] = []

    const wifiItem = SettingItem.create('仅 WiFi 下载')
      .setSubtitle('移动网络下不自动下载')
      .setShowSwitch(true)
      .setSwitchValue(this.wifiOnly)
      .setOnSwitchChange(async (value: boolean) => {
        this.wifiOnly = value
        await storageUtil.set('wifiOnly', value)
      })
    items.push(wifiItem)

    const dirItem = SettingItem.create('下载目录')
      .setSubtitle('/storage/Music/MusicFree')
      .setOnClick(() => {
        // TODO: 选择下载目录
      })
    items.push(dirItem)

    const qualityItem = SettingItem.create('下载音质')
      .setSubtitle('标准音质')
      .setOnClick(() => {
        this.showQualityPicker()
      })
    items.push(qualityItem)

    return items
  }

  getAppearanceSettings(): SettingItem[] {
    const items: SettingItem[] = []

    const darkModeItem = SettingItem.create('深色模式')
      .setSubtitle('跟随系统')
      .setOnClick(() => {
        this.showThemePicker()
      })
    items.push(darkModeItem)

    const themeItem = SettingItem.create('主题颜色')
      .setSubtitle('粉红色')
      .setOnClick(() => {
        // TODO: 主题颜色选择
      })
    items.push(themeItem)

    return items
  }

  getPluginSettings(): SettingItem[] {
    const items: SettingItem[] = []

    const manageItem = SettingItem.create('插件管理')
      .setSubtitle('已安装 0 个插件')
      .setOnClick(() => {
        this.navPathStack.pushPathByName('PluginManager', new EmptyRouteParam())
      })
    items.push(manageItem)

    const importItem = SettingItem.create('导入插件')
      .setOnClick(() => {
        this.showImportPluginDialog()
      })
    items.push(importItem)

    return items
  }

  getStorageSettings(): SettingItem[] {
    const items: SettingItem[] = []

    const cacheItem = SettingItem.create('清除缓存')
      .setSubtitle(this.cacheSize)
      .setOnClick(() => {
        this.showClearCacheDialog()
      })
    items.push(cacheItem)

    const historyItem = SettingItem.create('清除搜索历史')
      .setOnClick(() => {
        this.showClearHistoryDialog()
      })
    items.push(historyItem)

    return items
  }

  getAboutSettings(): SettingItem[] {
    const items: SettingItem[] = []

    const versionItem = SettingItem.create('版本')
      .setSubtitle('1.0.0 (HarmonyOS)')
      .setShowArrow(false)
    items.push(versionItem)

    const updateItem = SettingItem.create('检查更新')
      .setOnClick(() => {
        // TODO: 检查更新
      })
    items.push(updateItem)

    const licenseItem = SettingItem.create('开源许可')
      .setOnClick(() => {
        // TODO: 显示开源许可
      })
    items.push(licenseItem)

    const privacyItem = SettingItem.create('隐私政策')
      .setOnClick(() => {
        // TODO: 显示隐私政策
      })
    items.push(privacyItem)

    return items
  }

  @Builder
  SettingSection(title: string, items: SettingItem[]) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontColor($r('app.color.text_hint'))
        .width('100%')
        .padding({ left: 16, top: 16, bottom: 8 })

      Column() {
        ForEach(items, (item: SettingItem, index: number) => {
          Row() {
            if (item.icon !== null) {
              Image(item.icon)
                .width(22)
                .height(22)
                .fillColor($r('app.color.text_primary'))
                .margin({ right: 12 })
            }

            Column() {
              Text(item.title)
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))

              if (item.subtitle !== '') {
                Text(item.subtitle)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ top: 2 })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (item.showSwitch) {
              Toggle({ type: ToggleType.Switch, isOn: item.switchValue })
                .selectedColor($r('app.color.primary'))
                .onChange((isOn: boolean) => {
                  if (item.onSwitchChange !== null) {
                    item.onSwitchChange(isOn)
                  }
                })
            } else if (item.showArrow) {
              Image($r('app.media.ic_arrow_right'))
                .width(18)
                .height(18)
                .fillColor($r('app.color.text_hint'))
            }
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .backgroundColor($r('app.color.surface'))
          .onClick(() => {
            if (!item.showSwitch && item.onClick !== null) {
              item.onClick()
            }
          })

          if (index < items.length - 1) {
            Divider()
              .color($r('app.color.divider'))
              .margin({ left: item.icon !== null ? 50 : 16 })
          }
        })
      }
      .borderRadius(12)
      .margin({ left: 16, right: 16 })
      .clip(true)
    }
  }

  build() {
    NavDestination() {
      Column() {
        AppBar({
          title: '设置',
          showBack: true,
          onBackPress: () => {
            this.navPathStack.pop()
          }
        })

        Scroll() {
          Column() {
            // 播放设置
            this.SettingSection('播放', this.getPlaySettings())

            // 下载设置
            this.SettingSection('下载', this.getDownloadSettings())

            // 外观设置
            this.SettingSection('外观', this.getAppearanceSettings())

            // 插件设置
            this.SettingSection('插件', this.getPluginSettings())

            // 存储
            this.SettingSection('存储', this.getStorageSettings())

            // 关于
            this.SettingSection('关于', this.getAboutSettings())

            // 底部间距
            Row().height(32)
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      this.navPathStack.pop()
      return true
    })
  }

  showQualityPicker(): void {
    const sheets: SheetOption[] = []
    sheets.push(SheetOption.create('标准音质 (128kbps)', () => {}))
    sheets.push(SheetOption.create('高音质 (320kbps)', () => {}))
    sheets.push(SheetOption.create('无损音质', () => {}))

    ActionSheet.show({
      title: '下载音质',
      message: '请选择音质',
      sheets: sheets,
      cancel: () => {}
    })
  }

  showThemePicker(): void {
    const sheets: SheetOption[] = []
    sheets.push(SheetOption.create('跟随系统', () => {}))
    sheets.push(SheetOption.create('浅色模式', () => {}))
    sheets.push(SheetOption.create('深色模式', () => {}))

    ActionSheet.show({
      title: '深色模式',
      message: '请选择模式',
      sheets: sheets,
      cancel: () => {}
    })
  }

  showImportPluginDialog(): void {
    AlertDialog.show({
      title: '导入插件',
      message: '请输入插件链接或选择本地文件',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确定',
        action: () => {}
      }
    })
  }

  showClearCacheDialog(): void {
    AlertDialog.show({
      title: '清除缓存',
      message: `确定要清除 ${this.cacheSize} 的缓存吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清除',
        fontColor: $r('app.color.error'),
        action: () => {
          // TODO: 清除缓存
          this.cacheSize = '0 MB'
        }
      }
    })
  }

  showClearHistoryDialog(): void {
    AlertDialog.show({
      title: '清除搜索历史',
      message: '确定要清除所有搜索历史吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '清除',
        fontColor: $r('app.color.error'),
        action: () => {
          // TODO: 清除搜索历史
        }
      }
    })
  }
}