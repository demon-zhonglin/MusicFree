import { pluginEngine, MediaSourceResult, LyricResult, AlbumInfoResult, ArtistWorksResult } from '../service/PluginEngine'
import { Plugin } from '../model/Plugin'
import { MusicItem } from '../model/MusicItem'

@Observed
export class PluginManagerVM {
  plugins: Plugin[] = []
  isLoading: boolean = false
  error: string = ''

  constructor() {
    this.refreshPlugins()
  }

  refreshPlugins(): void {
    this.plugins = pluginEngine.getAllPlugins()
      .sort((a: Plugin, b: Plugin) => a.order - b.order)
  }

  get enabledPlugins(): Plugin[] {
    return this.plugins.filter((p: Plugin) => p.enabled)
  }

  get searchablePlugins(): Plugin[] {
    return this.enabledPlugins.filter((p: Plugin) => p.hasSearch)
  }

  getPluginByPlatform(platform: string): Plugin | null {
    const found = this.plugins.find((p: Plugin) => p.platform === platform)
    return found !== undefined ? found : null
  }

  async installFromUrl(url: string): Promise<Plugin | null> {
    this.isLoading = true
    this.error = ''

    try {
      const plugin = await pluginEngine.installPluginFromUrl(url)
      if (plugin) {
        this.refreshPlugins()
      } else {
        this.error = '安装插件失败'
      }
      return plugin
    } catch (err) {
      this.error = `安装插件失败: ${JSON.stringify(err)}`
      return null
    } finally {
      this.isLoading = false
    }
  }

  async installFromFile(filePath: string): Promise<Plugin | null> {
    this.isLoading = true
    this.error = ''

    try {
      const plugin = await pluginEngine.installPluginFromFile(filePath)
      if (plugin) {
        this.refreshPlugins()
      } else {
        this.error = '安装插件失败'
      }
      return plugin
    } catch (err) {
      this.error = `安装插件失败: ${JSON.stringify(err)}`
      return null
    } finally {
      this.isLoading = false
    }
  }

  async uninstall(plugin: Plugin): Promise<boolean> {
    this.isLoading = true
    this.error = ''

    try {
      const success = await pluginEngine.uninstallPlugin(plugin.hash)
      if (success) {
        this.refreshPlugins()
      } else {
        this.error = '卸载插件失败'
      }
      return success
    } catch (err) {
      this.error = `卸载插件失败: ${JSON.stringify(err)}`
      return false
    } finally {
      this.isLoading = false
    }
  }

  async updatePlugin(plugin: Plugin): Promise<Plugin | null> {
    if (plugin.srcUrl === '') {
      this.error = '该插件没有更新源'
      return null
    }

    this.isLoading = true
    this.error = ''

    try {
      const newPlugin = await pluginEngine.updatePlugin(plugin.hash)
      if (newPlugin) {
        this.refreshPlugins()
      } else {
        this.error = '更新插件失败'
      }
      return newPlugin
    } catch (err) {
      this.error = `更新插件失败: ${JSON.stringify(err)}`
      return null
    } finally {
      this.isLoading = false
    }
  }

  setPluginEnabled(plugin: Plugin, enabled: boolean): void {
    pluginEngine.setPluginEnabled(plugin.hash, enabled)
    this.refreshPlugins()
  }

  setPluginOrder(plugin: Plugin, order: number): void {
    pluginEngine.setPluginOrder(plugin.hash, order)
    this.refreshPlugins()
  }

  // 搜索相关方法
  async search(
    query: string,
    page: number = 1,
    type: string = 'music',
    pluginHash: string = ''
  ): Promise<Map<string, MusicItem[]>> {
    const results = new Map<string, MusicItem[]>()

    let pluginsToSearch: Plugin[] = []
    if (pluginHash !== '') {
      const p = pluginEngine.getPlugin(pluginHash)
      if (p) {
        pluginsToSearch.push(p)
      }
    } else {
      pluginsToSearch = this.searchablePlugins
    }

    for (const plugin of pluginsToSearch) {
      try {
        const items = await pluginEngine.search(plugin.hash, query, page, type)
        if (items.length > 0) {
          results.set(plugin.platform, items)
        }
      } catch (err) {
        console.error(`Search failed for plugin ${plugin.platform}:`, JSON.stringify(err))
      }
    }

    return results
  }

  // 获取播放源
  async getMediaSource(
    music: MusicItem,
    quality: string = 'standard'
  ): Promise<MediaSourceResult | null> {
    const plugin = pluginEngine.getPluginByPlatform(music.platform)
    if (!plugin) return null

    return await pluginEngine.getMediaSource(plugin.hash, music, quality)
  }

  // 获取歌词
  async getLyric(music: MusicItem): Promise<LyricResult | null> {
    const plugin = pluginEngine.getPluginByPlatform(music.platform)
    if (!plugin) return null

    return await pluginEngine.getLyric(plugin.hash, music)
  }

  // 获取专辑详情
  async getAlbumInfo(albumId: string, platform: string): Promise<AlbumInfoResult | null> {
    const plugin = pluginEngine.getPluginByPlatform(platform)
    if (!plugin) return null

    return await pluginEngine.getAlbumInfo(plugin.hash, albumId, platform)
  }

  // 获取艺术家作品
  async getArtistWorks(
    artistId: string,
    platform: string,
    page: number = 1,
    type: string = 'music'
  ): Promise<ArtistWorksResult | null> {
    const plugin = pluginEngine.getPluginByPlatform(platform)
    if (!plugin) return null

    return await pluginEngine.getArtistWorks(plugin.hash, artistId, platform, page, type)
  }
}

// 全局单例
let pluginManagerVMInstance: PluginManagerVM | null = null

export function getPluginManagerVM(): PluginManagerVM {
  if (!pluginManagerVMInstance) {
    pluginManagerVMInstance = new PluginManagerVM()
  }
  return pluginManagerVMInstance
}