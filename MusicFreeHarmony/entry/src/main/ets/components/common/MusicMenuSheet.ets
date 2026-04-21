import { MusicItem } from '../../model/MusicItem'
import { TrackPlayerVM, getTrackPlayerVM } from '../../viewmodel/TrackPlayerVM'
import { MusicSheetVM, getMusicSheetVM } from '../../viewmodel/MusicSheetVM'
import { SheetOption } from '../../constants/RouteConst'

/**
 * 音乐菜单选项类型
 */
export enum MusicMenuOption {
  PLAY_NEXT = 'play_next',           // 下一首播放
  ADD_TO_PLAYLIST = 'add_to_playlist', // 添加到播放列表
  FAVORITE = 'favorite',              // 收藏/取消收藏
  ADD_TO_SHEET = 'add_to_sheet',      // 添加到歌单
  REMOVE_FROM_SHEET = 'remove_from_sheet', // 从歌单移除
  DOWNLOAD = 'download',              // 下载
  SHARE = 'share',                    // 分享
  VIEW_ALBUM = 'view_album',          // 查看专辑
  VIEW_ARTIST = 'view_artist'         // 查看艺术家
}

/**
 * 音乐菜单配置
 */
export class MusicMenuConfig {
  music: MusicItem | null = null
  options: MusicMenuOption[] = [
    MusicMenuOption.PLAY_NEXT,
    MusicMenuOption.FAVORITE,
    MusicMenuOption.ADD_TO_SHEET
  ]
  sheetId: string = ''  // 当前歌单ID（用于移除操作）
  onRemoveFromSheet?: (music: MusicItem) => void
  
  static create(music: MusicItem): MusicMenuConfig {
    const config = new MusicMenuConfig()
    config.music = music
    return config
  }
  
  withOptions(options: MusicMenuOption[]): MusicMenuConfig {
    this.options = options
    return this
  }
  
  withSheetId(sheetId: string): MusicMenuConfig {
    this.sheetId = sheetId
    return this
  }
  
  withRemoveCallback(callback: (music: MusicItem) => void): MusicMenuConfig {
    this.onRemoveFromSheet = callback
    return this
  }
}

/**
 * 显示音乐操作菜单
 * @param config 菜单配置
 */
export function showMusicMenuSheet(config: MusicMenuConfig): void {
  if (!config.music) return
  
  const music = config.music
  const playerVM = getTrackPlayerVM()
  const sheetVM = getMusicSheetVM()
  const sheets: SheetOption[] = []
  
  // 根据配置添加选项
  for (const option of config.options) {
    switch (option) {
      case MusicMenuOption.PLAY_NEXT:
        sheets.push(SheetOption.create('下一首播放', () => {
          playerVM.addToPlayList(music, true)
        }))
        break
        
      case MusicMenuOption.ADD_TO_PLAYLIST:
        sheets.push(SheetOption.create('添加到播放列表', () => {
          playerVM.addToPlayList(music, false)
        }))
        break
        
      case MusicMenuOption.FAVORITE:
        sheets.push(SheetOption.create('收藏', async () => {
          await sheetVM.toggleFavorite(music)
        }))
        break
        
      case MusicMenuOption.ADD_TO_SHEET:
        sheets.push(SheetOption.create('添加到歌单', () => {
          // TODO: 显示歌单选择器
        }))
        break
        
      case MusicMenuOption.REMOVE_FROM_SHEET:
        if (config.sheetId !== '') {
          sheets.push(SheetOption.create('从歌单中移除', async () => {
            await sheetVM.removeMusicFromSheet(config.sheetId, music)
            if (config.onRemoveFromSheet) {
              config.onRemoveFromSheet(music)
            }
          }))
        }
        break
        
      case MusicMenuOption.DOWNLOAD:
        sheets.push(SheetOption.create('下载', () => {
          // TODO: 实现下载
        }))
        break
        
      case MusicMenuOption.SHARE:
        sheets.push(SheetOption.create('分享', () => {
          // TODO: 实现分享
        }))
        break
        
      case MusicMenuOption.VIEW_ALBUM:
        if (music.album) {
          sheets.push(SheetOption.create('查看专辑', () => {
            // TODO: 导航到专辑详情
          }))
        }
        break
        
      case MusicMenuOption.VIEW_ARTIST:
        if (music.artist) {
          sheets.push(SheetOption.create('查看艺术家', () => {
            // TODO: 导航到艺术家详情
          }))
        }
        break
    }
  }
  
  ActionSheet.show({
    title: music.title,
    message: '请选择操作',
    sheets: sheets,
    cancel: () => {}
  })
}

/**
 * 显示确认对话框
 * @param title 标题
 * @param message 消息
 * @param onConfirm 确认回调
 * @param confirmText 确认按钮文字
 * @param isDanger 是否为危险操作（红色按钮）
 */
export function showConfirmDialog(
  title: string,
  message: string,
  onConfirm: () => void,
  confirmText: string = '确定',
  isDanger: boolean = false
): void {
  AlertDialog.show({
    title: title,
    message: message,
    primaryButton: {
      value: '取消',
      action: () => {}
    },
    secondaryButton: {
      value: confirmText,
      fontColor: isDanger ? $r('app.color.error') : $r('app.color.primary'),
      action: onConfirm
    }
  })
}

/**
 * 显示删除确认对话框
 */
export function showDeleteConfirmDialog(
  itemName: string,
  onDelete: () => void
): void {
  showConfirmDialog(
    '删除确认',
    `确定要删除「${itemName}」吗？`,
    onDelete,
    '删除',
    true
  )
}

/**
 * 显示清空确认对话框
 */
export function showClearConfirmDialog(
  itemName: string,
  onClear: () => void
): void {
  showConfirmDialog(
    '清空确认',
    `确定要清空${itemName}吗？`,
    onClear,
    '清空',
    true
  )
}
