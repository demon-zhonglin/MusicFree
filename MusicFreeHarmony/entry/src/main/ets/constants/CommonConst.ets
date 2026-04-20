// 映射自 src/constants/commonConst.ts
export class CommonConst {
  static readonly SORT_INDEX_SYMBOL = Symbol('sortIndex')
  static readonly TIMESTAMP_SYMBOL = Symbol('timestamp')
  static readonly INTERNAL_FAKE_SOUND_KEY = 'fake-audio'
  static readonly MMKV_STORE_ID = 'musicfree-mmkv'
  static readonly APP_NAME = 'MusicFree'
}

// 播放模式
export enum MusicRepeatMode {
  QUEUE = 'queue',       // 列表循环
  SINGLE = 'single',     // 单曲循环
  SHUFFLE = 'shuffle'    // 随机播放
}
