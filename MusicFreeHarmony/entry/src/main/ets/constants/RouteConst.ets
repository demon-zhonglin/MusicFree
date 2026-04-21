// 路由常量，映射自 src/core/router/index.ts
export class RouteConst {
  static readonly HOME: string = 'Home'
  static readonly MUSIC_DETAIL: string = 'MusicDetail'
  static readonly SEARCH: string = 'Search'
  static readonly SETTING: string = 'Setting'
  static readonly TOP_LIST: string = 'TopList'
  static readonly TOP_LIST_DETAIL: string = 'TopListDetail'
  static readonly ALBUM_DETAIL: string = 'AlbumDetail'
  static readonly ARTIST_DETAIL: string = 'ArtistDetail'
  static readonly LOCAL_SHEET_DETAIL: string = 'LocalSheetDetail'
  static readonly PLUGIN_SHEET_DETAIL: string = 'PluginSheetDetail'
  static readonly LOCAL_MUSIC: string = 'LocalMusic'
  static readonly DOWNLOADING: string = 'Downloading'
  static readonly HISTORY: string = 'History'
  static readonly RECOMMEND_SHEETS: string = 'RecommendSheets'
}

// 路由参数类 - 空参数
export class EmptyRouteParam {
  placeholder: boolean = true
}

// 路由参数类 - 歌单详情
export class SheetDetailRouteParam {
  sheetId: string = ''

  static create(sheetId: string): SheetDetailRouteParam {
    const param = new SheetDetailRouteParam()
    param.sheetId = sheetId
    return param
  }
}

// 路由参数类 - 音乐详情
export class MusicDetailRouteParam {
  musicId: string = ''
  platform: string = ''

  static create(musicId: string, platform: string): MusicDetailRouteParam {
    const param = new MusicDetailRouteParam()
    param.musicId = musicId
    param.platform = platform
    return param
  }
}

// 路由参数类 - 搜索
export class SearchRouteParam {
  keyword: string = ''

  static create(keyword: string): SearchRouteParam {
    const param = new SearchRouteParam()
    param.keyword = keyword
    return param
  }
}

// ActionSheet 选项类
export class SheetOption {
  title: string = ''
  action: () => void = () => {}

  static create(title: string, action: () => void): SheetOption {
    const option = new SheetOption()
    option.title = title
    option.action = action
    return option
  }
}
