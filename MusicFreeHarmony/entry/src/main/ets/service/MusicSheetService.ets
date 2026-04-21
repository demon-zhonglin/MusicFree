import { relationalStore } from '@kit.ArkData'
import { MusicSheet } from '../model/MusicSheet'
import { MusicItem } from '../model/MusicItem'
import { Context } from '@kit.AbilityKit'

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'musicfree.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

const SQL_CREATE_SHEETS: string = `
  CREATE TABLE IF NOT EXISTS sheets (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    cover_img TEXT,
    create_at INTEGER,
    update_at INTEGER
  )
`

const SQL_CREATE_SHEET_MUSIC: string = `
  CREATE TABLE IF NOT EXISTS sheet_music (
    sheet_id TEXT NOT NULL,
    music_id TEXT NOT NULL,
    music_platform TEXT NOT NULL,
    music_data TEXT NOT NULL,
    sort_index INTEGER,
    PRIMARY KEY (sheet_id, music_id, music_platform)
  )
`

// 默认歌单常量
export const DEFAULT_SHEET_ID: string = 'favorite'
export const RECENT_PLAY_SHEET_ID: string = 'recent_play'

// 歌单更新信息类
export class SheetUpdateInfo {
  title: string = ''
  description: string = ''
}

class MusicSheetService {
  private rdbStore: relationalStore.RdbStore | null = null
  private initialized: boolean = false

  async init(context: Context): Promise<void> {
    if (this.initialized) return

    this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
    await this.rdbStore.executeSql(SQL_CREATE_SHEETS)
    await this.rdbStore.executeSql(SQL_CREATE_SHEET_MUSIC)

    // 创建默认歌单
    await this.ensureDefaultSheets()
    this.initialized = true
  }

  private async ensureDefaultSheets(): Promise<void> {
    // 确保"我喜欢"歌单存在
    const favorite = await this.getSheetById(DEFAULT_SHEET_ID)
    if (!favorite) {
      await this.createSheetWithId(DEFAULT_SHEET_ID, '我喜欢的音乐', '收藏的歌曲')
    }

    // 确保"最近播放"歌单存在
    const recent = await this.getSheetById(RECENT_PLAY_SHEET_ID)
    if (!recent) {
      await this.createSheetWithId(RECENT_PLAY_SHEET_ID, '最近播放', '最近播放的歌曲')
    }
  }

  private async createSheetWithId(id: string, title: string, description: string): Promise<MusicSheet> {
    const sheet = new MusicSheet()
    sheet.id = id
    sheet.title = title
    sheet.description = description
    sheet.createAt = Date.now()
    sheet.updateAt = Date.now()

    const values: relationalStore.ValuesBucket = {
      id: sheet.id,
      title: sheet.title,
      description: sheet.description,
      cover_img: sheet.coverImg,
      create_at: sheet.createAt,
      update_at: sheet.updateAt
    }

    if (this.rdbStore) {
      await this.rdbStore.insert('sheets', values)
    }
    return sheet
  }

  async createSheet(title: string, description: string = ''): Promise<MusicSheet> {
    const sheet = new MusicSheet()
    sheet.id = this.generateId()
    sheet.title = title
    sheet.description = description
    sheet.createAt = Date.now()
    sheet.updateAt = Date.now()

    const values: relationalStore.ValuesBucket = {
      id: sheet.id,
      title: sheet.title,
      description: sheet.description,
      cover_img: sheet.coverImg,
      create_at: sheet.createAt,
      update_at: sheet.updateAt
    }

    if (this.rdbStore) {
      await this.rdbStore.insert('sheets', values)
    }
    return sheet
  }

  async getAllSheets(): Promise<MusicSheet[]> {
    if (!this.rdbStore) return []

    const predicates = new relationalStore.RdbPredicates('sheets')
    predicates.orderByDesc('update_at')
    const resultSet = await this.rdbStore.query(predicates)

    const sheets: MusicSheet[] = []
    while (resultSet.goToNextRow()) {
      const sheet = new MusicSheet()
      sheet.id = resultSet.getString(resultSet.getColumnIndex('id'))
      sheet.title = resultSet.getString(resultSet.getColumnIndex('title'))
      sheet.description = resultSet.getString(resultSet.getColumnIndex('description'))
      sheet.coverImg = resultSet.getString(resultSet.getColumnIndex('cover_img'))
      sheet.createAt = resultSet.getLong(resultSet.getColumnIndex('create_at'))
      sheet.updateAt = resultSet.getLong(resultSet.getColumnIndex('update_at'))
      sheets.push(sheet)
    }
    resultSet.close()
    return sheets
  }

  async getUserSheets(): Promise<MusicSheet[]> {
    const allSheets = await this.getAllSheets()
    return allSheets.filter((s: MusicSheet) => s.id !== DEFAULT_SHEET_ID && s.id !== RECENT_PLAY_SHEET_ID)
  }

  async getSheetById(sheetId: string): Promise<MusicSheet | null> {
    if (!this.rdbStore) return null

    const predicates = new relationalStore.RdbPredicates('sheets')
    predicates.equalTo('id', sheetId)
    const resultSet = await this.rdbStore.query(predicates)

    if (!resultSet.goToNextRow()) {
      resultSet.close()
      return null
    }

    const sheet = new MusicSheet()
    sheet.id = resultSet.getString(resultSet.getColumnIndex('id'))
    sheet.title = resultSet.getString(resultSet.getColumnIndex('title'))
    sheet.description = resultSet.getString(resultSet.getColumnIndex('description'))
    sheet.coverImg = resultSet.getString(resultSet.getColumnIndex('cover_img'))
    sheet.createAt = resultSet.getLong(resultSet.getColumnIndex('create_at'))
    sheet.updateAt = resultSet.getLong(resultSet.getColumnIndex('update_at'))
    resultSet.close()

    return sheet
  }

  async getSheetWithMusic(sheetId: string): Promise<MusicSheet | null> {
    const sheet = await this.getSheetById(sheetId)
    if (!sheet) return null

    sheet.musicList = await this.getSheetMusic(sheetId)

    if (sheet.musicList.length > 0 && sheet.coverImg === '') {
      sheet.coverImg = sheet.musicList[0].artwork
    }

    return sheet
  }

  async getSheetMusic(sheetId: string): Promise<MusicItem[]> {
    if (!this.rdbStore) return []

    const predicates = new relationalStore.RdbPredicates('sheet_music')
    predicates.equalTo('sheet_id', sheetId)
    predicates.orderByAsc('sort_index')

    const resultSet = await this.rdbStore.query(predicates)
    const musicList: MusicItem[] = []

    while (resultSet.goToNextRow()) {
      const musicData = resultSet.getString(resultSet.getColumnIndex('music_data'))
      try {
        const parsed: Record<string, Object> = JSON.parse(musicData)
        const item = new MusicItem()
        item.id = parsed['id'] as string ?? ''
        item.platform = parsed['platform'] as string ?? ''
        item.title = parsed['title'] as string ?? ''
        item.artist = parsed['artist'] as string ?? ''
        item.album = parsed['album'] as string ?? ''
        item.artwork = parsed['artwork'] as string ?? ''
        item.url = parsed['url'] as string ?? ''
        item.duration = parsed['duration'] as number ?? 0
        musicList.push(item)
      } catch (e) {
        // 解析失败跳过
      }
    }
    resultSet.close()
    return musicList
  }

  async getSheetMusicCount(sheetId: string): Promise<number> {
    if (!this.rdbStore) return 0

    const predicates = new relationalStore.RdbPredicates('sheet_music')
    predicates.equalTo('sheet_id', sheetId)

    const resultSet = await this.rdbStore.query(predicates)
    let count = 0
    while (resultSet.goToNextRow()) {
      count++
    }
    resultSet.close()
    return count
  }

  async addMusicToSheet(sheetId: string, music: MusicItem): Promise<void> {
    await this.addMusicItemToSheet(sheetId, music)
    await this.updateSheetTime(sheetId)
  }

  async addMusicListToSheet(sheetId: string, musicList: MusicItem[]): Promise<void> {
    for (const item of musicList) {
      await this.addMusicItemToSheet(sheetId, item)
    }
    await this.updateSheetTime(sheetId)
  }

  private async addMusicItemToSheet(sheetId: string, item: MusicItem): Promise<void> {
    if (!this.rdbStore) return

    const existingMusic = await this.getSheetMusic(sheetId)
    const exists = existingMusic.some((m: MusicItem) => m.id === item.id && m.platform === item.platform)
    if (exists) return

    const sortIndex = existingMusic.length

    const values: relationalStore.ValuesBucket = {
      sheet_id: sheetId,
      music_id: item.id,
      music_platform: item.platform,
      music_data: JSON.stringify(item),
      sort_index: sortIndex
    }
    await this.rdbStore.insert('sheet_music', values)
  }

  async removeMusicFromSheet(sheetId: string, music: MusicItem): Promise<void> {
    if (!this.rdbStore) return

    const predicates = new relationalStore.RdbPredicates('sheet_music')
    predicates.equalTo('sheet_id', sheetId)
    predicates.equalTo('music_id', music.id)
    predicates.equalTo('music_platform', music.platform)

    await this.rdbStore.delete(predicates)
    await this.updateSheetTime(sheetId)
  }

  async isMusicInSheet(sheetId: string, music: MusicItem): Promise<boolean> {
    if (!this.rdbStore) return false

    const predicates = new relationalStore.RdbPredicates('sheet_music')
    predicates.equalTo('sheet_id', sheetId)
    predicates.equalTo('music_id', music.id)
    predicates.equalTo('music_platform', music.platform)

    const resultSet = await this.rdbStore.query(predicates)
    const exists = resultSet.goToNextRow()
    resultSet.close()
    return exists
  }

  async toggleFavorite(music: MusicItem): Promise<boolean> {
    const isFavorite = await this.isMusicInSheet(DEFAULT_SHEET_ID, music)
    if (isFavorite) {
      await this.removeMusicFromSheet(DEFAULT_SHEET_ID, music)
      return false
    } else {
      await this.addMusicToSheet(DEFAULT_SHEET_ID, music)
      return true
    }
  }

  async addToRecentPlay(music: MusicItem): Promise<void> {
    await this.removeMusicFromSheet(RECENT_PLAY_SHEET_ID, music)

    const existingMusic = await this.getSheetMusic(RECENT_PLAY_SHEET_ID)

    // 重新排序
    if (this.rdbStore) {
      for (let i = 0; i < existingMusic.length; i++) {
        const predicates = new relationalStore.RdbPredicates('sheet_music')
        predicates.equalTo('sheet_id', RECENT_PLAY_SHEET_ID)
        predicates.equalTo('music_id', existingMusic[i].id)
        predicates.equalTo('music_platform', existingMusic[i].platform)

        const values: relationalStore.ValuesBucket = {
          sort_index: i + 1
        }
        await this.rdbStore.update(values, predicates)
      }

      // 添加新音乐到最前面
      const values: relationalStore.ValuesBucket = {
        sheet_id: RECENT_PLAY_SHEET_ID,
        music_id: music.id,
        music_platform: music.platform,
        music_data: JSON.stringify(music),
        sort_index: 0
      }
      await this.rdbStore.insert('sheet_music', values)
    }

    // 限制最近播放数量（最多 100 首）
    const count = await this.getSheetMusicCount(RECENT_PLAY_SHEET_ID)
    if (count > 100) {
      const allMusic = await this.getSheetMusic(RECENT_PLAY_SHEET_ID)
      for (let i = 100; i < allMusic.length; i++) {
        await this.removeMusicFromSheet(RECENT_PLAY_SHEET_ID, allMusic[i])
      }
    }

    await this.updateSheetTime(RECENT_PLAY_SHEET_ID)
  }

  async deleteSheet(sheetId: string): Promise<void> {
    if (sheetId === DEFAULT_SHEET_ID || sheetId === RECENT_PLAY_SHEET_ID) {
      return
    }

    if (!this.rdbStore) return

    const musicPredicates = new relationalStore.RdbPredicates('sheet_music')
    musicPredicates.equalTo('sheet_id', sheetId)
    await this.rdbStore.delete(musicPredicates)

    const sheetPredicates = new relationalStore.RdbPredicates('sheets')
    sheetPredicates.equalTo('id', sheetId)
    await this.rdbStore.delete(sheetPredicates)
  }

  async updateSheetInfo(sheetId: string, title: string, description: string): Promise<void> {
    if (!this.rdbStore) return

    const values: relationalStore.ValuesBucket = {
      title: title,
      description: description,
      update_at: Date.now()
    }

    const predicates = new relationalStore.RdbPredicates('sheets')
    predicates.equalTo('id', sheetId)
    await this.rdbStore.update(values, predicates)
  }

  async updateSheet(sheetId: string, updates: SheetUpdateInfo): Promise<void> {
    await this.updateSheetInfo(sheetId, updates.title, updates.description)
  }

  async clearSheet(sheetId: string): Promise<void> {
    if (!this.rdbStore) return

    const predicates = new relationalStore.RdbPredicates('sheet_music')
    predicates.equalTo('sheet_id', sheetId)
    await this.rdbStore.delete(predicates)
    await this.updateSheetTime(sheetId)
  }

  private async updateSheetTime(sheetId: string): Promise<void> {
    if (!this.rdbStore) return

    const values: relationalStore.ValuesBucket = {
      update_at: Date.now()
    }
    const predicates = new relationalStore.RdbPredicates('sheets')
    predicates.equalTo('id', sheetId)
    await this.rdbStore.update(values, predicates)
  }

  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 9)
  }

  async destroy(): Promise<void> {
    this.rdbStore = null
    this.initialized = false
  }
}

export const musicSheetService = new MusicSheetService()