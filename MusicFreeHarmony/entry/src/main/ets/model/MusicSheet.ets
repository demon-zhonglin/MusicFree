import { MusicItem } from './MusicItem'

@Observed
export class MusicSheet {
  id: string = ''
  title: string = ''
  description?: string
  coverImg?: string
  musicList: MusicItem[] = []
  createAt: number = Date.now()
  updateAt: number = Date.now()

  constructor(data?: Partial<MusicSheet>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}
