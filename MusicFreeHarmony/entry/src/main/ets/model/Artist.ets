import { MediaBase } from './MusicItem'

@Observed
export class Artist extends MediaBase {
  name: string = ''
  avatar: string = ''
  description: string = ''
  worksNum: number = 0
  fans: number = 0
  extra: Map<string, Object> = new Map()

  constructor() {
    super()
  }

  static fromJson(data: Record<string, Object>): Artist {
    const artist = new Artist()
    artist.id = data['id'] as string ?? ''
    artist.platform = data['platform'] as string ?? ''
    artist.name = data['name'] as string ?? ''
    artist.avatar = data['avatar'] as string ?? ''
    artist.description = data['description'] as string ?? ''
    artist.worksNum = data['worksNum'] as number ?? 0
    artist.fans = data['fans'] as number ?? 0
    return artist
  }

  get uniqueKey(): string {
    return `${this.platform}@${this.id}`
  }
}
