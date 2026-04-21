import { MusicItem } from './MusicItem'

@Observed
export class MusicSheet {
  id: string = ''
  title: string = ''
  description: string = ''
  coverImg: string = ''
  musicList: MusicItem[] = []
  createAt: number = Date.now()
  updateAt: number = Date.now()

  constructor() {
  }

  static fromJson(data: Record<string, Object>): MusicSheet {
    const sheet = new MusicSheet()
    sheet.id = data['id'] as string ?? ''
    sheet.title = data['title'] as string ?? ''
    sheet.description = data['description'] as string ?? ''
    sheet.coverImg = data['coverImg'] as string ?? ''
    sheet.createAt = data['createAt'] as number ?? Date.now()
    sheet.updateAt = data['updateAt'] as number ?? Date.now()
    return sheet
  }
}
