@Observed
export class Plugin {
  name: string = ''
  platform: string = ''
  version?: string
  srcUrl?: string
  author?: string
  description?: string
  hash: string = ''
  enabled: boolean = true
  order: number = 0

  // 插件方法声明（实际由 JS Worker 执行）
  hasSearch: boolean = false
  hasGetMediaSource: boolean = false
  hasGetLyric: boolean = false
  hasGetAlbumInfo: boolean = false
  hasGetArtistWorks: boolean = false
  hasGetTopLists: boolean = false
  hasGetRecommendSheets: boolean = false
}
