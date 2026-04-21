import { Plugin } from '../model/Plugin'
import { PluginManagerVM, getPluginManagerVM } from '../viewmodel/PluginManagerVM'
import { AppBar } from '../components/base/AppBar'
import { Empty } from '../components/base/Empty'
import { IconButton } from '../components/base/IconButton'
import { SheetOption } from '../constants/RouteConst'

@Builder
export function PluginManagerBuilder() {
  PluginManager()
}

@Entry
@Component
struct PluginManager {
  @State pluginVM: PluginManagerVM = getPluginManagerVM()
  @State isImporting: boolean = false
  @State importUrl: string = ''
  private navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.pluginVM.refreshPlugins()
  }

  @Builder
  PluginItem(plugin: Plugin) {
    Row() {
      // 插件图标
      Column() {
        Text(plugin.platform.charAt(0).toUpperCase())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(48)
      .height(48)
      .borderRadius(12)
      .backgroundColor($r('app.color.primary'))
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(plugin.name || plugin.platform)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (plugin.version) {
            Text(`v${plugin.version}`)
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
              .margin({ left: 8 })
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(4)
              .backgroundColor($r('app.color.chip_background'))
          }
        }

        Row() {
          if (plugin.author) {
            Text(plugin.author)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }

          Text(this.getPluginCapabilities(plugin))
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
            .margin({ left: plugin.author ? 8 : 0 })
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // 开关
      Toggle({ type: ToggleType.Switch, isOn: plugin.enabled })
        .selectedColor($r('app.color.primary'))
        .onChange((isOn) => {
          this.pluginVM.setPluginEnabled(plugin, isOn)
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .onClick(() => {
      this.showPluginDetail(plugin)
    })
  }

  getPluginCapabilities(plugin: Plugin): string {
    const caps: string[] = []
    if (plugin.hasSearch) caps.push('搜索')
    if (plugin.hasGetTopLists) caps.push('排行')
    if (plugin.hasGetRecommendSheets) caps.push('推荐')
    return caps.length > 0 ? caps.join(' · ') : ''
  }

  build() {
    NavDestination() {
      Column() {
        AppBar({
          title: '插件管理',
          showBack: true,
          onBackPress: () => {
            this.navPathStack.pop()
          },
          rightContent: () => {
            IconButton({
              icon: $r('app.media.ic_add'),
              iconSize: 24,
              onButtonClick: () => {
                this.showImportDialog()
              }
            })
          }
        })

        if (this.pluginVM.isLoading) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color($r('app.color.primary'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.pluginVM.plugins.length === 0) {
          Empty({
            title: '暂无插件',
            description: '点击右上角添加插件'
          })
          .layoutWeight(1)
        } else {
          List() {
            ForEach(this.pluginVM.plugins, (plugin: Plugin) => {
              ListItem() {
                this.PluginItem(plugin)
              }
            }, (plugin: Plugin) => plugin.hash)
          }
          .width('100%')
          .layoutWeight(1)
          .divider({
            strokeWidth: 0.5,
            color: $r('app.color.divider'),
            startMargin: 76,
            endMargin: 16
          })
        }

        // 底部提示
        if (this.pluginVM.plugins.length > 0) {
          Text('长按插件可进行更多操作')
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
            .padding(16)
        }
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

  showImportDialog(): void {
    AlertDialog.show({
      title: '导入插件',
      message: '请选择导入方式',
      buttons: [
        {
          value: '从链接导入',
          action: () => {
            this.showUrlInputDialog()
          }
        },
        {
          value: '从本地文件导入',
          action: () => {
            this.importFromFile()
          }
        },
        {
          value: '取消',
          action: () => {}
        }
      ]
    })
  }

  showUrlInputDialog(): void {
    // TODO: 实现 URL 输入弹窗
    // HarmonyOS 暂无原生输入弹窗，需要自定义 CustomDialog
    AlertDialog.show({
      title: '从链接导入',
      message: '请在设置中输入插件订阅链接',
      confirm: {
        value: '知道了',
        action: () => {}
      }
    })
  }

  async importFromFile(): Promise<void> {
    // TODO: 实现文件选择
    AlertDialog.show({
      title: '从文件导入',
      message: '请选择 .js 插件文件',
      confirm: {
        value: '知道了',
        action: () => {}
      }
    })
  }

  showPluginDetail(plugin: Plugin): void {
    const sheets: SheetOption[] = []
    sheets.push(SheetOption.create(plugin.enabled ? '禁用插件' : '启用插件', () => {
      this.pluginVM.setPluginEnabled(plugin, !plugin.enabled)
    }))
    sheets.push(SheetOption.create('更新插件', async () => {
      if (plugin.srcUrl !== '') {
        await this.pluginVM.updatePlugin(plugin)
      } else {
        AlertDialog.show({
          title: '无法更新',
          message: '该插件没有更新源',
          confirm: { value: '知道了', action: () => {} }
        })
      }
    }))
    sheets.push(SheetOption.create('查看详情', () => {
      this.showPluginInfo(plugin)
    }))
    sheets.push(SheetOption.create('卸载插件', () => {
      this.showUninstallConfirm(plugin)
    }))

    ActionSheet.show({
      title: plugin.name !== '' ? plugin.name : plugin.platform,
      message: '请选择操作',
      sheets: sheets,
      cancel: () => {}
    })
  }

  showPluginInfo(plugin: Plugin): void {
    const info = [
      `平台: ${plugin.platform}`,
      `版本: ${plugin.version || '未知'}`,
      `作者: ${plugin.author || '未知'}`,
      `描述: ${plugin.description || '无'}`,
      `哈希: ${plugin.hash.slice(0, 8)}...`
    ].join('\n')

    AlertDialog.show({
      title: '插件详情',
      message: info,
      confirm: {
        value: '关闭',
        action: () => {}
      }
    })
  }

  showUninstallConfirm(plugin: Plugin): void {
    AlertDialog.show({
      title: '卸载插件',
      message: `确定要卸载「${plugin.name || plugin.platform}」吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '卸载',
        fontColor: $r('app.color.error'),
        action: async () => {
          await this.pluginVM.uninstall(plugin)
        }
      }
    })
  }
}
