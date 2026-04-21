import { worker } from '@kit.ArkTS'
import { fileIo } from '@kit.CoreFileKit'
import { Plugin } from '../model/Plugin'
import { MusicItem } from '../model/MusicItem'
import { util } from '@kit.ArkTS'
import { http } from '@kit.NetworkKit'

export class PluginMethodResult {
  success: boolean = false
  data: string = ''
  error: string = ''
}

export class PluginInfo {
  platform: string = ''
  version: string = ''
  author: string = ''
  description: string = ''
}

export class MediaSourceResult {
  url: string = ''
  headers: Map<string, string> = new Map()
}

export class LyricResult {
  lrc: string = ''
  tlyric: string = ''
}

export class AlbumInfoResult {
  musicList: MusicItem[] = []
}

export class ArtistWorksResult {
  data: MusicItem[] = []
  isEnd: boolean = false
}

class PluginEngine {
  private plugins: Map<string, Plugin> = new Map()
  private workers: Map<string, worker.ThreadWorker> = new Map()
  private pluginDir: string = ''
  private initialized: boolean = false

  async init(sandboxPath: string): Promise<void> {
    if (this.initialized) return

    this.pluginDir = `${sandboxPath}/plugins`
    try {
      await fileIo.mkdir(this.pluginDir)
    } catch (e) {
      // 目录已存在
    }
    await this.loadInstalledPlugins()
    this.initialized = true
  }

  private async loadInstalledPlugins(): Promise<void> {
    try {
      const files = await fileIo.listFile(this.pluginDir)
      for (const file of files) {
        if (file.endsWith('.js')) {
          await this.loadPlugin(`${this.pluginDir}/${file}`)
        }
      }
    } catch (err) {
      console.error('Load plugins failed:', JSON.stringify(err))
    }
  }

  private async loadPlugin(pluginPath: string): Promise<void> {
    try {
      const file = await fileIo.open(pluginPath, fileIo.OpenMode.READ_ONLY)
      const stat = await fileIo.stat(pluginPath)
      const buffer = new ArrayBuffer(stat.size)
      await fileIo.read(file.fd, buffer)
      await fileIo.close(file)

      const textDecoder = util.TextDecoder.create('utf-8')
      const code = textDecoder.decodeToString(new Uint8Array(buffer))

      const pluginInfo = this.parsePluginInfo(code)
      if (pluginInfo.platform === '') return

      const hashValue = this.calculateHash(code)

      const plugin = new Plugin()
      plugin.platform = pluginInfo.platform
      plugin.name = pluginInfo.platform
      plugin.version = pluginInfo.version
      plugin.author = pluginInfo.author
      plugin.description = pluginInfo.description
      plugin.hash = hashValue
      plugin.hasSearch = code.includes('search')
      plugin.hasGetMediaSource = code.includes('getMediaSource')
      plugin.hasGetLyric = code.includes('getLyric')
      plugin.hasGetAlbumInfo = code.includes('getAlbumInfo')
      plugin.hasGetArtistWorks = code.includes('getArtistWorks')
      plugin.hasGetTopLists = code.includes('getTopLists')
      plugin.hasGetRecommendSheets = code.includes('getRecommendSheetTags')

      this.plugins.set(hashValue, plugin)
    } catch (err) {
      console.error('Load plugin failed:', pluginPath, JSON.stringify(err))
    }
  }

  async installPluginFromUrl(url: string): Promise<Plugin | null> {
    try {
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'text/plain' }
      })
      httpRequest.destroy()

      if (response.responseCode !== http.ResponseCode.OK) {
        throw new Error(`HTTP Error: ${response.responseCode}`)
      }

      const code = response.result as string
      return await this.installPlugin(code, url)
    } catch (err) {
      console.error('Install plugin from URL failed:', JSON.stringify(err))
      return null
    }
  }

  async installPluginFromFile(filePath: string): Promise<Plugin | null> {
    try {
      const file = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY)
      const stat = await fileIo.stat(filePath)
      const buffer = new ArrayBuffer(stat.size)
      await fileIo.read(file.fd, buffer)
      await fileIo.close(file)

      const textDecoder = util.TextDecoder.create('utf-8')
      const code = textDecoder.decodeToString(new Uint8Array(buffer))
      return await this.installPlugin(code, '')
    } catch (err) {
      console.error('Install plugin from file failed:', JSON.stringify(err))
      return null
    }
  }

  private async installPlugin(code: string, srcUrl: string): Promise<Plugin | null> {
    const hashValue = this.calculateHash(code)

    if (this.plugins.has(hashValue)) {
      console.info('Plugin already installed:', hashValue)
      const existingPlugin = this.plugins.get(hashValue)
      return existingPlugin !== undefined ? existingPlugin : null
    }

    const pluginInfo = this.parsePluginInfo(code)
    if (pluginInfo.platform === '') {
      console.error('Invalid plugin: cannot parse plugin info')
      return null
    }

    const plugin = new Plugin()
    plugin.platform = pluginInfo.platform
    plugin.name = pluginInfo.platform
    plugin.version = pluginInfo.version
    plugin.author = pluginInfo.author
    plugin.description = pluginInfo.description
    plugin.srcUrl = srcUrl
    plugin.hash = hashValue
    plugin.hasSearch = code.includes('search')
    plugin.hasGetMediaSource = code.includes('getMediaSource')
    plugin.hasGetLyric = code.includes('getLyric')
    plugin.hasGetAlbumInfo = code.includes('getAlbumInfo')
    plugin.hasGetArtistWorks = code.includes('getArtistWorks')
    plugin.hasGetTopLists = code.includes('getTopLists')
    plugin.hasGetRecommendSheets = code.includes('getRecommendSheetTags')

    // 保存插件文件
    const pluginPath = `${this.pluginDir}/${hashValue}.js`
    const file = await fileIo.open(pluginPath,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
    const textEncoder = new util.TextEncoder()
    const codeBuffer = textEncoder.encodeInto(code)
    await fileIo.write(file.fd, codeBuffer.buffer)
    await fileIo.close(file)

    this.plugins.set(hashValue, plugin)
    return plugin
  }

  private parsePluginInfo(code: string): PluginInfo {
    const info = new PluginInfo()

    const platformMatch = code.match(/platform\s*[:=]\s*['"]([^'"]+)['"]/)
    if (platformMatch && platformMatch[1]) {
      info.platform = platformMatch[1]
    }

    const versionMatch = code.match(/version\s*[:=]\s*['"]([^'"]+)['"]/)
    if (versionMatch && versionMatch[1]) {
      info.version = versionMatch[1]
    }

    const authorMatch = code.match(/author\s*[:=]\s*['"]([^'"]+)['"]/)
    if (authorMatch && authorMatch[1]) {
      info.author = authorMatch[1]
    }

    const descMatch = code.match(/description\s*[:=]\s*['"]([^'"]+)['"]/)
    if (descMatch && descMatch[1]) {
      info.description = descMatch[1]
    }

    return info
  }

  private calculateHash(content: string): string {
    let hashNum = 0
    for (let i = 0; i < content.length; i++) {
      const char = content.charCodeAt(i)
      hashNum = ((hashNum << 5) - hashNum) + char
      hashNum = hashNum & hashNum
    }
    return Math.abs(hashNum).toString(16).padStart(32, '0').slice(0, 32)
  }

  // 搜索音乐
  async search(
    pluginHash: string,
    query: string,
    page: number,
    type: string
  ): Promise<MusicItem[]> {
    const plugin = this.plugins.get(pluginHash)
    if (!plugin || !plugin.hasSearch) return []
    // TODO: 实现实际的插件调用
    return []
  }

  // 获取播放源
  async getMediaSource(
    pluginHash: string,
    music: MusicItem,
    quality: string
  ): Promise<MediaSourceResult | null> {
    const plugin = this.plugins.get(pluginHash)
    if (!plugin || !plugin.hasGetMediaSource) return null
    // TODO: 实现实际的插件调用
    return null
  }

  // 获取歌词
  async getLyric(
    pluginHash: string,
    music: MusicItem
  ): Promise<LyricResult | null> {
    const plugin = this.plugins.get(pluginHash)
    if (!plugin || !plugin.hasGetLyric) return null
    // TODO: 实现实际的插件调用
    return null
  }

  // 获取专辑信息
  async getAlbumInfo(
    pluginHash: string,
    albumId: string,
    platform: string
  ): Promise<AlbumInfoResult | null> {
    const plugin = this.plugins.get(pluginHash)
    if (!plugin || !plugin.hasGetAlbumInfo) return null
    // TODO: 实现实际的插件调用
    return null
  }

  // 获取艺术家作品
  async getArtistWorks(
    pluginHash: string,
    artistId: string,
    platform: string,
    page: number,
    type: string
  ): Promise<ArtistWorksResult | null> {
    const plugin = this.plugins.get(pluginHash)
    if (!plugin || !plugin.hasGetArtistWorks) return null
    // TODO: 实现实际的插件调用
    return null
  }

  getPlugin(hash: string): Plugin | null {
    const plugin = this.plugins.get(hash)
    return plugin !== undefined ? plugin : null
  }

  getPluginByPlatform(platform: string): Plugin | null {
    for (const plugin of this.plugins.values()) {
      if (plugin.platform === platform) {
        return plugin
      }
    }
    return null
  }

  getAllPlugins(): Plugin[] {
    return Array.from(this.plugins.values())
  }

  getEnabledPlugins(): Plugin[] {
    return this.getAllPlugins().filter((p: Plugin) => p.enabled)
  }

  getPluginsWithSearch(): Plugin[] {
    return this.getEnabledPlugins().filter((p: Plugin) => p.hasSearch)
  }

  async uninstallPlugin(hash: string): Promise<boolean> {
    const plugin = this.plugins.get(hash)
    if (!plugin) return false

    // 终止 Worker
    const workerInstance = this.workers.get(hash)
    if (workerInstance) {
      workerInstance.terminate()
      this.workers.delete(hash)
    }

    // 删除文件
    try {
      await fileIo.unlink(`${this.pluginDir}/${hash}.js`)
    } catch (e) {
      // 忽略错误
    }

    this.plugins.delete(hash)
    return true
  }

  setPluginEnabled(hash: string, enabled: boolean): void {
    const plugin = this.plugins.get(hash)
    if (plugin) {
      plugin.enabled = enabled
    }
  }

  setPluginOrder(hash: string, order: number): void {
    const plugin = this.plugins.get(hash)
    if (plugin) {
      plugin.order = order
    }
  }

  async updatePlugin(hash: string): Promise<Plugin | null> {
    const plugin = this.plugins.get(hash)
    if (!plugin || plugin.srcUrl === '') return null

    await this.uninstallPlugin(hash)
    return await this.installPluginFromUrl(plugin.srcUrl)
  }

  async destroy(): Promise<void> {
    for (const workerInstance of this.workers.values()) {
      workerInstance.terminate()
    }
    this.workers.clear()
    this.plugins.clear()
    this.initialized = false
  }
}

export const pluginEngine = new PluginEngine()