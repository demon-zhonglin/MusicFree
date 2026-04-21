// 映射自 src/constants/commonConst.ts
export class CommonConst {
  // ArkTS 不支持 Symbol，使用字符串常量替代
  static readonly SORT_INDEX_KEY: string = '__sortIndex__'
  static readonly TIMESTAMP_KEY: string = '__timestamp__'
  static readonly INTERNAL_FAKE_SOUND_KEY: string = 'fake-audio'
  static readonly MMKV_STORE_ID: string = 'musicfree-mmkv'
  static readonly APP_NAME: string = 'MusicFree'
}

// 播放模式
export enum MusicRepeatMode {
  QUEUE = 'queue',       // 列表循环
  SINGLE = 'single',     // 单曲循环
  SHUFFLE = 'shuffle'    // 随机播放
}
