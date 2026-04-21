import { MediaBase } from './MusicItem'
import { MusicItem } from './MusicItem'

@Observed
export class Album extends MediaBase {
  title: string = ''
  artist: string = ''
  artwork: string = ''
  description: string = ''
  date: string = ''
  musicList: MusicItem[] = []
  extra: Map<string, Object> = new Map()

  constructor() {
    super()
  }

  static fromJson(data: Record<string, Object>): Album {
    const album = new Album()
    album.id = data['id'] as string ?? ''
    album.platform = data['platform'] as string ?? ''
    album.title = data['title'] as string ?? ''
    album.artist = data['artist'] as string ?? ''
    album.artwork = data['artwork'] as string ?? ''
    album.description = data['description'] as string ?? ''
    album.date = data['date'] as string ?? ''
    return album
  }

  get uniqueKey(): string {
    return `${this.platform}@${this.id}`
  }
}
