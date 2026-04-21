// 映射自 src/types/music.d.ts
// 品质等级常量
export class QualityKey {
  static readonly LOW: string = 'low'
  static readonly STANDARD: string = 'standard'
  static readonly HIGH: string = 'high'
  static readonly SUPER: string = 'super'
}

// 媒体基类
export class MediaBase {
  id: string = ''
  platform: string = ''
}

export class QualityInfo {
  url: string = ''
  size: number = 0
}

@Observed
export class MusicItem extends MediaBase {
  title: string = ''
  artist: string = ''
  album: string = ''
  artwork: string = ''
  url: string = ''
  duration: number = 0
  lrc: string = ''
  qualities: Map<string, QualityInfo> = new Map()
  extra: Map<string, Object> = new Map()

  constructor() {
    super()
  }

  static fromJson(data: Record<string, Object>): MusicItem {
    const item = new MusicItem()
    item.id = data['id'] as string ?? ''
    item.platform = data['platform'] as string ?? ''
    item.title = data['title'] as string ?? ''
    item.artist = data['artist'] as string ?? ''
    item.album = data['album'] as string ?? ''
    item.artwork = data['artwork'] as string ?? ''
    item.url = data['url'] as string ?? ''
    item.duration = data['duration'] as number ?? 0
    item.lrc = data['lrc'] as string ?? ''
    return item
  }

  get uniqueKey(): string {
    return `${this.platform}@${this.id}`
  }
}
