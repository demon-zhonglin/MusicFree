/**
 * 格式化工具类
 * 提供时间、数字、字符串等常用格式化方法
 */
export class FormatUtil {
  /**
   * 格式化时间（毫秒转为 mm:ss 格式）
   * @param ms 毫秒数
   * @returns 格式化后的时间字符串
   */
  static formatTime(ms: number): string {
    if (ms <= 0 || !Number.isFinite(ms)) {
      return '00:00'
    }
    
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }
  
  /**
   * 格式化时间（毫秒转为 HH:mm:ss 格式）
   * @param ms 毫秒数
   * @returns 格式化后的时间字符串
   */
  static formatTimeWithHour(ms: number): string {
    if (ms <= 0 || !Number.isFinite(ms)) {
      return '00:00:00'
    }
    
    const totalSeconds = Math.floor(ms / 1000)
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60
    
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }
  
  /**
   * 格式化播放次数
   * @param count 播放次数
   * @returns 格式化后的字符串（如：1.2万、3.5亿）
   */
  static formatPlayCount(count: number): string {
    if (count < 0) return '0'
    if (count < 10000) {
      return count.toString()
    } else if (count < 100000000) {
      return `${(count / 10000).toFixed(1)}万`
    } else {
      return `${(count / 100000000).toFixed(1)}亿`
    }
  }
  
  /**
   * 格式化文件大小
   * @param bytes 字节数
   * @returns 格式化后的字符串（如：1.2 MB）
   */
  static formatFileSize(bytes: number): string {
    if (bytes < 0) return '0 B'
    
    const units = ['B', 'KB', 'MB', 'GB', 'TB']
    let unitIndex = 0
    let size = bytes
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024
      unitIndex++
    }
    
    return `${size.toFixed(1)} ${units[unitIndex]}`
  }
  
  /**
   * 格式化日期
   * @param timestamp 时间戳（毫秒）
   * @param format 格式（'date' | 'time' | 'datetime'）
   * @returns 格式化后的日期字符串
   */
  static formatDate(timestamp: number, format: string = 'datetime'): string {
    const date = new Date(timestamp)
    
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    
    switch (format) {
      case 'date':
        return `${year}-${month}-${day}`
      case 'time':
        return `${hour}:${minute}`
      case 'datetime':
      default:
        return `${year}-${month}-${day} ${hour}:${minute}`
    }
  }
  
  /**
   * 格式化相对时间（如：刚刚、5分钟前、昨天）
   * @param timestamp 时间戳（毫秒）
   * @returns 相对时间字符串
   */
  static formatRelativeTime(timestamp: number): string {
    const now = Date.now()
    const diff = now - timestamp
    
    if (diff < 60000) {
      return '刚刚'
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`
    } else if (diff < 172800000) {
      return '昨天'
    } else if (diff < 604800000) {
      return `${Math.floor(diff / 86400000)}天前`
    } else {
      return FormatUtil.formatDate(timestamp, 'date')
    }
  }
  
  /**
   * 截断字符串并添加省略号
   * @param str 原字符串
   * @param maxLength 最大长度
   * @returns 截断后的字符串
   */
  static truncate(str: string, maxLength: number): string {
    if (str.length <= maxLength) {
      return str
    }
    return str.substring(0, maxLength - 1) + '…'
  }
  
  /**
   * 格式化艺术家名称列表
   * @param artists 艺术家名称数组
   * @returns 格式化后的字符串（如：歌手A、歌手B）
   */
  static formatArtists(artists: string[]): string {
    if (!artists || artists.length === 0) {
      return '未知艺术家'
    }
    return artists.filter(a => a).join('、')
  }
}

/**
 * 播放工具类
 * 提供播放相关的辅助方法
 */
export class PlayUtil {
  /**
   * 播放音乐并处理播放源获取
   * @param music 音乐项
   * @param index 在列表中的索引
   * @param playList 播放列表
   * @param playerVM 播放器 ViewModel
   * @param pluginVM 插件管理 ViewModel
   * @param sheetVM 歌单 ViewModel（可选，用于添加到最近播放）
   */
  static async playMusic(
    music: import('../model/MusicItem').MusicItem,
    index: number,
    playList: import('../model/MusicItem').MusicItem[],
    playerVM: import('../viewmodel/TrackPlayerVM').TrackPlayerVM,
    pluginVM: import('../viewmodel/PluginManagerVM').PluginManagerVM,
    sheetVM?: import('../viewmodel/MusicSheetVM').MusicSheetVM
  ): Promise<void> {
    // 获取播放源
    const source = await pluginVM.getMediaSource(music)
    if (source?.url) {
      music.url = source.url
    }
    
    // 设置播放列表并播放
    playerVM.setPlayList(playList, index)
    await playerVM.play(music)
    
    // 添加到最近播放
    if (sheetVM) {
      await sheetVM.addToRecentPlay(music)
    }
  }
}
