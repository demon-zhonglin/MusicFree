import { musicSheetService, DEFAULT_SHEET_ID, RECENT_PLAY_SHEET_ID, SheetUpdateInfo } from '../service/MusicSheetService'
import { MusicSheet } from '../model/MusicSheet'
import { MusicItem } from '../model/MusicItem'

export { RECENT_PLAY_SHEET_ID }

@Observed
export class MusicSheetVM {
  sheets: MusicSheet[] = []
  favoriteSheet: MusicSheet | null = null
  recentPlaySheet: MusicSheet | null = null
  currentSheet: MusicSheet | null = null
  isLoading: boolean = false
  error: string = ''

  constructor() {
    this.refreshSheets()
  }

  async refreshSheets(): Promise<void> {
    this.isLoading = true
    this.error = ''

    try {
      this.sheets = await musicSheetService.getAllSheets()

      // 获取系统歌单
      this.favoriteSheet = await musicSheetService.getSheetWithMusic(DEFAULT_SHEET_ID)
      this.recentPlaySheet = await musicSheetService.getSheetWithMusic(RECENT_PLAY_SHEET_ID)
    } catch (err) {
      this.error = `加载歌单失败: ${err}`
    } finally {
      this.isLoading = false
    }
  }

  get userSheets(): MusicSheet[] {
    return this.sheets.filter(s => s.id !== DEFAULT_SHEET_ID && s.id !== RECENT_PLAY_SHEET_ID)
  }

  get favoriteCount(): number {
    return this.favoriteSheet?.musicList?.length ?? 0
  }

  get recentPlayCount(): number {
    return this.recentPlaySheet?.musicList?.length ?? 0
  }

  async loadSheet(sheetId: string): Promise<MusicSheet | null> {
    this.isLoading = true
    this.error = ''

    try {
      this.currentSheet = await musicSheetService.getSheetWithMusic(sheetId)
      return this.currentSheet
    } catch (err) {
      this.error = `加载歌单失败: ${err}`
      return null
    } finally {
      this.isLoading = false
    }
  }

  async createSheet(title: string, description?: string): Promise<MusicSheet | null> {
    this.isLoading = true
    this.error = ''

    try {
      const sheet = await musicSheetService.createSheet(title, description)
      await this.refreshSheets()
      return sheet
    } catch (err) {
      this.error = `创建歌单失败: ${err}`
      return null
    } finally {
      this.isLoading = false
    }
  }

  async deleteSheet(sheetId: string): Promise<boolean> {
    // 不允许删除系统歌单
    if (sheetId === DEFAULT_SHEET_ID || sheetId === RECENT_PLAY_SHEET_ID) {
      this.error = '无法删除系统歌单'
      return false
    }

    this.isLoading = true
    this.error = ''

    try {
      await musicSheetService.deleteSheet(sheetId)
      await this.refreshSheets()
      return true
    } catch (err) {
      this.error = `删除歌单失败: ${err}`
      return false
    } finally {
      this.isLoading = false
    }
  }

  async updateSheet(sheetId: string, updates: SheetUpdateInfo): Promise<boolean> {
    this.isLoading = true
    this.error = ''

    try {
      await musicSheetService.updateSheet(sheetId, updates)
      await this.refreshSheets()
      return true
    } catch (err) {
      this.error = `更新歌单失败: ${err}`
      return false
    } finally {
      this.isLoading = false
    }
  }

  async addMusicToSheet(sheetId: string, music: MusicItem | MusicItem[]): Promise<boolean> {
    try {
      if (Array.isArray(music)) {
        for (const item of music) {
          await musicSheetService.addMusicToSheet(sheetId, item)
        }
      } else {
        await musicSheetService.addMusicToSheet(sheetId, music)
      }
      await this.refreshSheets()

      // 如果当前正在查看这个歌单，重新加载
      if (this.currentSheet !== null && this.currentSheet.id === sheetId) {
        await this.loadSheet(sheetId)
      }
      return true
    } catch (err) {
      this.error = `添加音乐失败: ${err}`
      return false
    }
  }

  async removeMusicFromSheet(sheetId: string, music: MusicItem): Promise<boolean> {
    try {
      await musicSheetService.removeMusicFromSheet(sheetId, music)
      await this.refreshSheets()

      // 如果当前正在查看这个歌单，重新加载
      if (this.currentSheet?.id === sheetId) {
        await this.loadSheet(sheetId)
      }
      return true
    } catch (err) {
      this.error = `移除音乐失败: ${err}`
      return false
    }
  }

  async toggleFavorite(music: MusicItem): Promise<boolean> {
    try {
      const isFavorite = await musicSheetService.toggleFavorite(music)
      await this.refreshSheets()
      return isFavorite
    } catch (err) {
      this.error = `操作失败: ${err}`
      return false
    }
  }

  async isFavorite(music: MusicItem): Promise<boolean> {
    return await musicSheetService.isMusicInSheet(DEFAULT_SHEET_ID, music)
  }

  async addToRecentPlay(music: MusicItem): Promise<void> {
    try {
      await musicSheetService.addToRecentPlay(music)
      // 静默更新最近播放，不需要刷新所有歌单
      this.recentPlaySheet = await musicSheetService.getSheetWithMusic(RECENT_PLAY_SHEET_ID)
    } catch (err) {
      console.error('Add to recent play failed:', err)
    }
  }

  async clearRecentPlay(): Promise<boolean> {
    try {
      await musicSheetService.clearSheet(RECENT_PLAY_SHEET_ID)
      await this.refreshSheets()
      return true
    } catch (err) {
      this.error = `清空最近播放失败: ${err}`
      return false
    }
  }

  async clearSheet(sheetId: string): Promise<boolean> {
    try {
      await musicSheetService.clearSheet(sheetId)
      await this.refreshSheets()

      if (this.currentSheet?.id === sheetId) {
        await this.loadSheet(sheetId)
      }
      return true
    } catch (err) {
      this.error = `清空歌单失败: ${err}`
      return false
    }
  }

  getSheetById(sheetId: string): MusicSheet | undefined {
    return this.sheets.find(s => s.id === sheetId)
  }
}

// 全局单例
let musicSheetVMInstance: MusicSheetVM | null = null

export function getMusicSheetVM(): MusicSheetVM {
  if (!musicSheetVMInstance) {
    musicSheetVMInstance = new MusicSheetVM()
  }
  return musicSheetVMInstance
}
