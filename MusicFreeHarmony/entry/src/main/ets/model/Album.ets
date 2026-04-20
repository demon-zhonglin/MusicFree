import { IMediaBase } from './MusicItem'
import { MusicItem } from './MusicItem'

@Observed
export class Album implements IMediaBase {
  id: string = ''
  platform: string = ''
  title: string = ''
  artist?: string
  artwork?: string
  description?: string
  date?: string
  musicList?: MusicItem[]
  extra?: Record<string, unknown>

  constructor(data?: Partial<Album>) {
    if (data) {
      Object.assign(this, data)
    }
  }

  get uniqueKey(): string {
    return `${this.platform}@${this.id}`
  }
}
