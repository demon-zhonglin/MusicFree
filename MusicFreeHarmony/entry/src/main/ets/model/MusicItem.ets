// 映射自 src/types/music.d.ts
export type QualityKey = 'low' | 'standard' | 'high' | 'super'

export interface IMediaBase {
  id: string
  platform: string
}

@Observed
export class MusicItem implements IMediaBase {
  id: string = ''
  platform: string = ''
  title: string = ''
  artist: string = ''
  album?: string
  artwork?: string
  url?: string
  duration?: number
  lrc?: string
  qualities?: Record<QualityKey, { url?: string; size?: number }>
  extra?: Record<string, unknown>

  constructor(data?: Partial<MusicItem>) {
    if (data) {
      Object.assign(this, data)
    }
  }

  get uniqueKey(): string {
    return `${this.platform}@${this.id}`
  }
}
