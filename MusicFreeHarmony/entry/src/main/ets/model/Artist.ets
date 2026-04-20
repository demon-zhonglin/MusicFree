import { IMediaBase } from './MusicItem'

@Observed
export class Artist implements IMediaBase {
  id: string = ''
  platform: string = ''
  name: string = ''
  avatar?: string
  description?: string
  worksNum?: number
  fans?: number
  extra?: Record<string, unknown>

  constructor(data?: Partial<Artist>) {
    if (data) {
      Object.assign(this, data)
    }
  }

  get uniqueKey(): string {
    return `${this.platform}@${this.id}`
  }
}
