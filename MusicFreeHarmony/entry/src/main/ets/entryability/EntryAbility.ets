import { UIAbility } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { playbackService } from '../service/PlaybackService'
import { pluginEngine } from '../service/PluginEngine'
import { musicSheetService } from '../service/MusicSheetService'
import { storageUtil } from '../utils/StorageUtil'
import { getTrackPlayerVM } from '../viewmodel/TrackPlayerVM'

export default class EntryAbility extends UIAbility {
  async onCreate(): Promise<void> {
    console.info('EntryAbility onCreate')

    // 初始化存储
    await storageUtil.init(this.context)

    // 初始化歌单服务
    await musicSheetService.init(this.context)

    // 初始化插件引擎
    const sandboxPath = this.context.filesDir
    await pluginEngine.init(sandboxPath)

    // 初始化播放服务
    await playbackService.init(this.context)
  }

  async onDestroy(): Promise<void> {
    console.info('EntryAbility onDestroy')
    
    // 移除事件监听器
    const playerVM = getTrackPlayerVM()
    playerVM.teardownListeners()
    
    // 异步销毁服务（确保资源完全释放）
    await playbackService.destroy()
    await pluginEngine.destroy()
    await musicSheetService.destroy()
    
    console.info('EntryAbility onDestroy completed')
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    console.info('EntryAbility onWindowStageCreate')

    // 设置沉浸式状态栏
    const mainWindow = await windowStage.getMainWindow()
    await mainWindow.setWindowLayoutFullScreen(true)

    // 设置状态栏透明
    const systemBarProperties: window.SystemBarProperties = {
      statusBarColor: '#00000000',
      navigationBarColor: '#00000000',
      statusBarContentColor: '#000000',
      navigationBarContentColor: '#000000'
    }
    await mainWindow.setWindowSystemBarProperties(systemBarProperties)

    // 加载首页
    windowStage.loadContent('pages/Home', (err) => {
      if (err.code) {
        console.error('Failed to load content:', JSON.stringify(err))
        return
      }
      console.info('Succeeded in loading content')
    })
  }

  onWindowStageDestroy(): void {
    console.info('EntryAbility onWindowStageDestroy')
  }

  onForeground(): void {
    console.info('EntryAbility onForeground')
  }

  onBackground(): void {
    console.info('EntryAbility onBackground')
  }
}