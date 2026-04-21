# MusicFree HarmonyOS 6 + ArkTS 重构计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 MusicFree 从 React Native 完全重写为原生 HarmonyOS 6 应用，使用 ArkTS 语言

---

## 📊 执行进度跟踪

**最后更新:** 2026-04-21 13:35

| Phase | Task | 状态 | 完成时间 | 备注 |
|-------|------|------|----------|------|
| Phase 1 | Task 1.1: 创建项目框架 | ✅ 完成 | 2026-04-20 | DevEco Studio 创建 |
| Phase 1 | Task 1.2: 创建数据模型层 | ✅ 完成 | 2026-04-20 | 5 个模型文件 |
| Phase 1 | Task 1.3: 创建常量和工具类 | ✅ 完成 | 2026-04-20 | 4 个工具文件 |
| Phase 2 | Task 2.1: 实现 AVPlayer 播放服务 | ✅ 完成 | 2026-04-21 | PlaybackService + TrackPlayerVM |
| Phase 2 | Task 2.2: 实现插件引擎 | ✅ 完成 | 2026-04-21 | PluginEngine + PluginManagerVM |
| Phase 2 | Task 2.3: 实现歌单管理服务 | ✅ 完成 | 2026-04-21 | MusicSheetService + MusicSheetVM |
| Phase 3 | Task 3.1: 实现基础组件 | ✅ 完成 | 2026-04-21 | 5 个基础组件 |
| Phase 3 | Task 3.2: 实现音乐组件 | ✅ 完成 | 2026-04-21 | 3 个音乐组件 |
| Phase 3 | Task 3.3: 实现首页 | ✅ 完成 | 2026-04-21 | Home.ets |
| Phase 3 | Task 3.4: 实现播放详情页 | ✅ 完成 | 2026-04-21 | MusicDetail.ets |
| Phase 3 | Task 3.5: 实现搜索页 | ✅ 完成 | 2026-04-21 | Search.ets |
| Phase 4 | Task 4.1: 实现设置页 | ✅ 完成 | 2026-04-21 | Setting.ets |
| Phase 4 | Task 4.2: 实现歌单详情页 | ✅ 完成 | 2026-04-21 | SheetDetail.ets |
| Phase 4 | Task 4.3: 实现播放历史页 | ✅ 完成 | 2026-04-21 | History.ets |
| Phase 4 | Task 4.4: 实现插件管理页 | ✅ 完成 | 2026-04-21 | PluginManager.ets |
| Phase 4 | Task 4.5: 资源与配置文件 | ✅ 完成 | 2026-04-21 | 路由/图标/Ability |
| **ArkTS** | **ArkTS 严格模式适配** | ✅ 完成 | 2026-04-21 | 详见下方 |
| Phase 5 | 测试与优化 | ⏳ 待执行 | - | - |

### ArkTS 严格模式适配记录 (2026-04-21)

在编译过程中遇到多个 ArkTS 严格模式限制，以下是修复记录：

| 错误代码 | 问题描述 | 修复方案 | 影响文件 |
|----------|----------|----------|----------|
| `arkts-no-symbol` | `Symbol()` API 不支持 | 改为字符串常量 | `CommonConst.ets` |
| `arkts-no-obj-literals-as-types` | 对象字面量不能作为类型 | 定义显式类 | `MusicItem.ets`, `MusicSheetVM.ets` |
| `arkts-no-untyped-obj-literals` | 未类型化的对象字面量 | 使用类实例替代 | `PlaybackService.ets`, `Setting.ets` 等 |
| `arkts-no-noninferrable-arr-literals` | 数组字面量类型不可推断 | 定义 `SheetOption` 类 | 所有使用 ActionSheet 的页面 |
| Property 'size' conflict | 属性名与内置方法冲突 | 重命名为 `imageSize`/`iconSize` | `MusicImage.ets`, `IconButton.ets` |
| `backgroundTaskManager` API | 参数类型不匹配 | 添加 wantAgent 参数 | `PlaybackService.ets` |
| `emitter` API | 事件 ID 必须为数字 | 改为数字常量 + `InnerEvent` | `PlaybackService.ets`, `TrackPlayerVM.ets` |

#### 关键代码模式变更

**1. 数据模型：从 `interface` + `Partial<T>` 改为 `class` + `static fromJson()`**
```typescript
// ❌ 旧模式 (不兼容)
interface IMediaBase { id: string; platform: string }
export class MusicItem implements IMediaBase {
  constructor(data?: Partial<MusicItem>) { Object.assign(this, data) }
}

// ✅ 新模式 (ArkTS 兼容)
export class MediaBase { id: string = ''; platform: string = '' }
export class MusicItem extends MediaBase {
  constructor() { super() }
  static fromJson(data: Record<string, Object>): MusicItem { ... }
}
```

**2. 事件系统：使用 `emitter.InnerEvent` + 数字 ID**
```typescript
// ❌ 旧模式
emitter.emit({ eventId: 'stateChanged' }, { data: state })

// ✅ 新模式
export class PlaybackEvents {
  static readonly STATE_CHANGED: number = 1001
}
const innerEvent: emitter.InnerEvent = { eventId: PlaybackEvents.STATE_CHANGED }
const eventData: emitter.EventData = { data: new Map([['state', state]]) }
emitter.emit(innerEvent, eventData)
```

**3. 组件属性：避免与内置属性冲突**
```typescript
// ❌ 冲突的属性名
@Prop size: number = 24  // 与 CustomComponent.size() 冲突

// ✅ 重命名属性
@Prop iconSize: number = 24
@Prop imageSize: number = 48
@Prop buttonPadding: number = 8
```

**4. ActionSheet：使用类型化的选项类**
```typescript
// ❌ 对象字面量数组
sheets: [{ title: '选项', action: () => {} }]

// ✅ 类型化数组
export class SheetOption {
  title: string = ''
  action: () => void = () => {}
  static create(title: string, action: () => void): SheetOption { ... }
}
const sheets: SheetOption[] = []
sheets.push(SheetOption.create('选项', () => {}))
```

**5. 路由参数：使用显式参数类**
```typescript
// ❌ 对象字面量
navPathStack.pushPathByName('SheetDetail', { sheetId: '123' })

// ✅ 参数类
export class SheetDetailRouteParam {
  sheetId: string = ''
  static create(sheetId: string): SheetDetailRouteParam { ... }
}
navPathStack.pushPathByName('SheetDetail', SheetDetailRouteParam.create('123'))
```

### 已创建文件清单

**数据模型层 (`entry/src/main/ets/model/`):**
- [x] `MusicItem.ets` - 音乐项数据模型
- [x] `MusicSheet.ets` - 歌单数据模型
- [x] `Plugin.ets` - 插件数据模型
- [x] `Album.ets` - 专辑数据模型
- [x] `Artist.ets` - 艺术家数据模型

**常量层 (`entry/src/main/ets/constants/`):**
- [x] `CommonConst.ets` - 通用常量和播放模式枚举
- [x] `RouteConst.ets` - 路由路径常量

**工具类 (`entry/src/main/ets/utils/`):**
- [x] `StorageUtil.ets` - 持久化存储工具
- [x] `NetworkUtil.ets` - 网络请求工具

**服务层 (`entry/src/main/ets/service/`):**
- [x] `PlaybackService.ets` - AVPlayer 播放服务 (含 AVSession 后台控制)
- [x] `PluginEngine.ets` - 插件引擎 (Worker 隔离执行 JS 插件)
- [x] `MusicSheetService.ets` - 歌单管理服务 (RDB 数据库存储)

**ViewModel 层 (`entry/src/main/ets/viewmodel/`):**
- [x] `TrackPlayerVM.ets` - 播放器状态管理 ViewModel
- [x] `PluginManagerVM.ets` - 插件管理 ViewModel
- [x] `MusicSheetVM.ets` - 歌单管理 ViewModel

**基础组件 (`entry/src/main/ets/components/base/`):**
- [x] `AppBar.ets` - 顶部导航栏
- [x] `IconButton.ets` - 图标按钮 (含 Filled 变体)
- [x] `MusicImage.ets` - 音乐封面图 (含 Circle 变体)
- [x] `Empty.ets` - 空状态组件 (含 Action 变体)
- [x] `Chip.ets` - 标签组件 (含 ChipGroup)

**音乐组件 (`entry/src/main/ets/components/music/`):**
- [x] `MusicItemView.ets` - 音乐列表项 (含 Compact 变体)
- [x] `MusicList.ets` - 音乐列表 (含 Header 变体)
- [x] `MusicBar.ets` - 底部播放栏

**资源文件 (`entry/src/main/resources/`):**
- [x] `base/element/color.json` - 颜色资源定义

**页面 (`entry/src/main/ets/pages/`):**
- [x] `Home.ets` - 首页 (歌单列表、快捷入口、底部播放栏)
- [x] `MusicDetail.ets` - 播放详情页 (旋转封面、进度条、控制按钮)
- [x] `Search.ets` - 搜索页 (多平台搜索、历史记录)
- [x] `Setting.ets` - 设置页 (播放/下载/外观/插件/存储/关于)
- [x] `SheetDetail.ets` - 歌单详情页 (歌单信息、播放全部、音乐列表)
- [x] `History.ets` - 播放历史页 (历史列表、清空)
- [x] `PluginManager.ets` - 插件管理页 (插件列表、导入/卸载)

**入口与配置 (`entry/src/main/ets/entryability/`):**
- [x] `EntryAbility.ets` - 应用入口 Ability (服务初始化、沉浸式状态栏)

**资源文件 (`entry/src/main/resources/base/`):**
- [x] `element/color.json` - 颜色资源 (16 种颜色)
- [x] `element/string.json` - 字符串资源
- [x] `profile/main_pages.json` - 页面配置
- [x] `profile/router_map.json` - 路由映射配置
- [x] `media/*.svg` - 图标资源 (27 个 SVG 图标)

**模块配置:**
- [x] `module.json5` - 模块配置 (权限、后台模式、路由)

---

**Architecture:** 采用 MVVM 架构模式，使用 ArkUI 声明式 UI 框架，结合 HarmonyOS 6 的分布式能力和媒体服务

**Tech Stack:** HarmonyOS 6 SDK, ArkTS 5.0, ArkUI, AVPlayer, @ohos/axios, @ohos/mmkv

---

## 一、项目概览

### 1.1 当前技术栈 (React Native)
| 模块 | 技术 |
|------|------|
| UI框架 | React Native 0.76.5 |
| 状态管理 | Jotai |
| 导航 | React Navigation 6 |
| 音频播放 | react-native-track-player |
| 存储 | MMKV |
| 网络请求 | Axios |

### 1.2 目标技术栈 (HarmonyOS 6)
| 模块 | 技术 |
|------|------|
| UI框架 | ArkUI (声明式) |
| 状态管理 | @State/@Prop/@Link/@Observed |
| 导航 | Navigation + NavPathStack |
| 音频播放 | @ohos.multimedia.media (AVPlayer) |
| 存储 | @ohos.data.preferences + MMKV |
| 网络请求 | @ohos.net.http + @ohos/axios |

---

## 二、功能模块映射

### 2.1 核心模块映射表

| RN 模块 | 文件路径 | HarmonyOS 对应方案 | 优先级 |
|---------|----------|-------------------|--------|
| TrackPlayer | `src/core/trackPlayer/` | AVPlayer + AVSession | P0 |
| PluginManager | `src/core/pluginManager/` | Worker + JS Engine | P0 |
| MusicSheet | `src/core/musicSheet/` | DataAbility + RDB | P1 |
| LyricManager | `src/core/lyricManager.ts` | FileIO + Parser | P1 |
| Downloader | `src/core/downloader.ts` | @ohos.request | P1 |
| AppConfig | `src/core/appConfig.ts` | Preferences | P1 |
| Theme | `src/core/theme.ts` | @ohos.app.ability | P2 |
| I18n | `src/core/i18n/` | Resource Management | P2 |

### 2.2 页面映射表

| 页面 | RN 路径 | ArkTS 路径 | 复杂度 |
|------|---------|-----------|--------|
| 首页 | `src/pages/home/` | `entry/src/main/ets/pages/Home.ets` | 高 |
| 播放详情 | `src/pages/musicDetail/` | `entry/src/main/ets/pages/MusicDetail.ets` | 高 |
| 搜索 | `src/pages/searchPage/` | `entry/src/main/ets/pages/Search.ets` | 中 |
| 设置 | `src/pages/setting/` | `entry/src/main/ets/pages/Setting.ets` | 中 |
| 排行榜 | `src/pages/topList/` | `entry/src/main/ets/pages/TopList.ets` | 低 |
| 专辑详情 | `src/pages/albumDetail/` | `entry/src/main/ets/pages/AlbumDetail.ets` | 中 |
| 艺术家详情 | `src/pages/artistDetail/` | `entry/src/main/ets/pages/ArtistDetail.ets` | 中 |
| 本地音乐 | `src/pages/localMusic/` | `entry/src/main/ets/pages/LocalMusic.ets` | 中 |
| 下载管理 | `src/pages/downloading/` | `entry/src/main/ets/pages/Downloading.ets` | 中 |
| 播放历史 | `src/pages/history/` | `entry/src/main/ets/pages/History.ets` | 低 |

---

## 三、HarmonyOS 6 项目结构

```
MusicFreeHarmony/
├── AppScope/                           # 应用全局配置
│   ├── app.json5                       # 应用配置
│   └── resources/                      # 全局资源
├── entry/                              # 主模块
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/           # Ability入口
│   │   │   │   └── EntryAbility.ets
│   │   │   ├── pages/                  # 页面组件
│   │   │   │   ├── Index.ets           # 主入口页面
│   │   │   │   ├── Home.ets            # 首页
│   │   │   │   ├── MusicDetail.ets     # 播放详情
│   │   │   │   ├── Search.ets          # 搜索
│   │   │   │   └── ...
│   │   │   ├── components/             # 可复用组件
│   │   │   │   ├── base/               # 基础组件
│   │   │   │   ├── music/              # 音乐相关组件
│   │   │   │   ├── dialogs/            # 对话框
│   │   │   │   └── panels/             # 面板
│   │   │   ├── viewmodel/              # ViewModel层
│   │   │   │   ├── TrackPlayerVM.ets
│   │   │   │   ├── MusicSheetVM.ets
│   │   │   │   └── PluginManagerVM.ets
│   │   │   ├── model/                  # 数据模型
│   │   │   │   ├── MusicItem.ets
│   │   │   │   ├── MusicSheet.ets
│   │   │   │   ├── Plugin.ets
│   │   │   │   └── ...
│   │   │   ├── service/                # 后台服务
│   │   │   │   ├── PlaybackService.ets
│   │   │   │   └── DownloadService.ets
│   │   │   ├── utils/                  # 工具类
│   │   │   │   ├── StorageUtil.ets
│   │   │   │   ├── NetworkUtil.ets
│   │   │   │   ├── LyricParser.ets
│   │   │   │   └── ...
│   │   │   └── constants/              # 常量
│   │   │       ├── CommonConst.ets
│   │   │       └── RouteConst.ets
│   │   ├── resources/                  # 资源文件
│   │   │   ├── base/
│   │   │   │   ├── element/            # 字符串、颜色等
│   │   │   │   ├── media/              # 图片资源
│   │   │   │   └── profile/            # 配置文件
│   │   │   └── rawfile/                # 原始文件
│   │   └── module.json5                # 模块配置
│   └── build-profile.json5
├── commons/                            # 公共模块 (HAR)
│   └── plugin-engine/                  # 插件引擎模块
├── oh_modules/                         # 第三方依赖
└── oh-package.json5                    # 依赖配置
```

---

## 四、分阶段实施计划

### Phase 1: 项目基础搭建 (预计 2 天)

#### Task 1.1: 创建 HarmonyOS 6 项目框架

**Files:**
- Create: `MusicFreeHarmony/AppScope/app.json5`
- Create: `MusicFreeHarmony/entry/src/main/module.json5`
- Create: `MusicFreeHarmony/oh-package.json5`
- Create: `MusicFreeHarmony/build-profile.json5`

**Step 1: 使用 DevEco Studio 创建新项目**
- 打开 DevEco Studio 5.0+
- 创建新项目: File → New → Create Project
- 选择模板: Application → Empty Ability
- 配置: API 12, ArkTS, Stage Model

**Step 2: 配置 app.json5**
```json5
{
  "app": {
    "bundleName": "com.demon.musicfree",
    "vendor": "猫头猫",
    "versionCode": 62,
    "versionName": "0.6.2",
    "icon": "$media:app_icon",
    "label": "$string:app_name",
    "minAPIVersion": 12,
    "targetAPIVersion": 12
  }
}
```

**Step 3: 配置 module.json5**
```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": ["phone", "tablet"],
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
      { "name": "ohos.permission.READ_MEDIA" },
      { "name": "ohos.permission.WRITE_MEDIA" },
      { "name": "ohos.permission.KEEP_BACKGROUND_RUNNING" }
    ],
    "abilities": [{
      "name": "EntryAbility",
      "srcEntry": "./ets/entryability/EntryAbility.ets",
      "launchType": "singleton",
      "skills": [{
        "entities": ["entity.system.home"],
        "actions": ["action.system.home"]
      }],
      "backgroundModes": ["audioPlayback"]
    }]
  }
}
```

**Step 4: 配置依赖 oh-package.json5**
```json5
{
  "name": "musicfree",
  "version": "0.6.2",
  "description": "MusicFree for HarmonyOS",
  "main": "",
  "author": "猫头猫",
  "license": "AGPL-3.0",
  "dependencies": {
    "@ohos/axios": "^2.2.0",
    "@aspect/mmkv": "^2.0.0"
  },
  "devDependencies": {
    "@ohos/hypium": "1.0.6"
  }
}
```

**Step 5: Commit**
```bash
git add MusicFreeHarmony/
git commit -m "feat: initialize HarmonyOS 6 project structure"
```

---

#### Task 1.2: 创建数据模型层

**Files:**
- Create: `entry/src/main/ets/model/MusicItem.ets`
- Create: `entry/src/main/ets/model/MusicSheet.ets`
- Create: `entry/src/main/ets/model/Plugin.ets`
- Create: `entry/src/main/ets/model/Album.ets`
- Create: `entry/src/main/ets/model/Artist.ets`

**Step 1: 创建 MusicItem.ets**
```typescript
// 映射自 src/types/music.d.ts
export type QualityKey = 'low' | 'standard' | 'high' | 'super'

export interface IMediaBase {
  id: string
  platform: string
}

@Observed
export class MusicItem implements IMediaBase {
  id: string = ''
  platform: string = ''
  title: string = ''
  artist: string = ''
  album?: string
  artwork?: string
  url?: string
  duration?: number
  lrc?: string
  qualities?: Record<QualityKey, { url?: string; size?: number }>
  extra?: Record<string, unknown>

  constructor(data?: Partial<MusicItem>) {
    if (data) {
      Object.assign(this, data)
    }
  }

  get uniqueKey(): string {
    return `${this.platform}@${this.id}`
  }
}
```

**Step 2: 创建 MusicSheet.ets**
```typescript
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
```

**Step 3: 创建 Plugin.ets**
```typescript
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
```

**Step 4: Commit**
```bash
git add entry/src/main/ets/model/
git commit -m "feat: add data models (MusicItem, MusicSheet, Plugin)"
```

---

#### Task 1.3: 创建常量和工具类

**Files:**
- Create: `entry/src/main/ets/constants/CommonConst.ets`
- Create: `entry/src/main/ets/constants/RouteConst.ets`
- Create: `entry/src/main/ets/utils/StorageUtil.ets`
- Create: `entry/src/main/ets/utils/NetworkUtil.ets`

**Step 1: 创建 CommonConst.ets**
```typescript
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
```

**Step 2: 创建 RouteConst.ets**
```typescript
// 路由常量，映射自 src/core/router/index.ts
export class RouteConst {
  static readonly HOME = 'Home'
  static readonly MUSIC_DETAIL = 'MusicDetail'
  static readonly SEARCH = 'Search'
  static readonly SETTING = 'Setting'
  static readonly TOP_LIST = 'TopList'
  static readonly TOP_LIST_DETAIL = 'TopListDetail'
  static readonly ALBUM_DETAIL = 'AlbumDetail'
  static readonly ARTIST_DETAIL = 'ArtistDetail'
  static readonly LOCAL_SHEET_DETAIL = 'LocalSheetDetail'
  static readonly PLUGIN_SHEET_DETAIL = 'PluginSheetDetail'
  static readonly LOCAL_MUSIC = 'LocalMusic'
  static readonly DOWNLOADING = 'Downloading'
  static readonly HISTORY = 'History'
  static readonly RECOMMEND_SHEETS = 'RecommendSheets'
}
```

**Step 3: 创建 StorageUtil.ets**
```typescript
import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

const PREFERENCES_NAME = 'musicfree_preferences'

class StorageUtil {
  private context?: Context
  private store?: preferences.Preferences

  async init(context: Context): Promise<void> {
    this.context = context
    this.store = await preferences.getPreferences(context, PREFERENCES_NAME)
  }

  async get<T>(key: string, defaultValue?: T): Promise<T | undefined> {
    if (!this.store) return defaultValue
    try {
      const value = await this.store.get(key, defaultValue)
      return value as T
    } catch {
      return defaultValue
    }
  }

  async set(key: string, value: preferences.ValueType): Promise<void> {
    if (!this.store) return
    await this.store.put(key, value)
    await this.store.flush()
  }

  async remove(key: string): Promise<void> {
    if (!this.store) return
    await this.store.delete(key)
    await this.store.flush()
  }
}

export const storageUtil = new StorageUtil()
```

**Step 4: Commit**
```bash
git add entry/src/main/ets/constants/ entry/src/main/ets/utils/
git commit -m "feat: add constants and utility classes"
```

---

### Phase 2: 核心服务层 (预计 5-7 天)

#### Task 2.1: 实现 AVPlayer 播放服务

**Files:**
- Create: `entry/src/main/ets/service/PlaybackService.ets`
- Create: `entry/src/main/ets/viewmodel/TrackPlayerVM.ets`

**关键技术点:**
- 使用 `@ohos.multimedia.media` 的 AVPlayer
- 使用 AVSession 实现后台播放控制
- 使用 BackgroundTaskManager 保持后台运行

**Step 1: 创建 PlaybackService.ets**
```typescript
import { media } from '@kit.MediaKit'
import { avSession } from '@kit.AVSessionKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { MusicItem } from '../model/MusicItem'
import { MusicRepeatMode } from '../constants/CommonConst'
import { emitter } from '@kit.BasicServicesKit'

export enum PlaybackState {
  IDLE = 'idle',
  LOADING = 'loading',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
}

// 播放器事件
export const PlaybackEvents = {
  STATE_CHANGED: 'playbackStateChanged',
  TRACK_CHANGED: 'trackChanged',
  PROGRESS_CHANGED: 'progressChanged',
  PLAY_END: 'playEnd'
}

class PlaybackService {
  private avPlayer?: media.AVPlayer
  private session?: avSession.AVSession
  private playList: MusicItem[] = []
  private currentIndex: number = -1
  private repeatMode: MusicRepeatMode = MusicRepeatMode.QUEUE
  private _state: PlaybackState = PlaybackState.IDLE

  get state(): PlaybackState {
    return this._state
  }

  get currentMusic(): MusicItem | undefined {
    return this.playList[this.currentIndex]
  }

  get duration(): number {
    return this.avPlayer?.duration ?? 0
  }

  get position(): number {
    return this.avPlayer?.currentTime ?? 0
  }

  async init(context: Context): Promise<void> {
    // 创建 AVPlayer
    this.avPlayer = await media.createAVPlayer()
    this.setupPlayerCallbacks()
    
    // 创建 AVSession
    this.session = await avSession.createAVSession(context, 'MusicFree', 'audio')
    await this.session.activate()
    this.setupSessionCallbacks()
    
    // 申请后台长时任务
    await this.startBackgroundTask(context)
  }

  private setupPlayerCallbacks(): void {
    if (!this.avPlayer) return

    this.avPlayer.on('stateChange', (state) => {
      switch (state) {
        case 'idle':
          this._state = PlaybackState.IDLE
          break
        case 'initialized':
        case 'prepared':
          this._state = PlaybackState.LOADING
          break
        case 'playing':
          this._state = PlaybackState.PLAYING
          break
        case 'paused':
          this._state = PlaybackState.PAUSED
          break
        case 'completed':
          this.handlePlayEnd()
          break
        case 'stopped':
          this._state = PlaybackState.STOPPED
          break
        case 'error':
          this._state = PlaybackState.ERROR
          break
      }
      this.emitEvent(PlaybackEvents.STATE_CHANGED, { state: this._state })
    })

    this.avPlayer.on('timeUpdate', (time) => {
      this.emitEvent(PlaybackEvents.PROGRESS_CHANGED, {
        position: time,
        duration: this.duration
      })
    })
  }

  private setupSessionCallbacks(): void {
    this.session?.on('play', () => this.play())
    this.session?.on('pause', () => this.pause())
    this.session?.on('playNext', () => this.skipToNext())
    this.session?.on('playPrevious', () => this.skipToPrevious())
  }

  private async startBackgroundTask(context: Context): Promise<void> {
    const wantAgentInfo: backgroundTaskManager.BackgroundMode = 'audioPlayback'
    await backgroundTaskManager.startBackgroundRunning(
      context,
      wantAgentInfo,
      undefined
    )
  }

  async play(music?: MusicItem): Promise<void> {
    if (music) {
      const index = this.findMusicIndex(music)
      if (index >= 0) {
        this.currentIndex = index
      } else {
        this.playList.push(music)
        this.currentIndex = this.playList.length - 1
      }
    }

    const current = this.currentMusic
    if (!current?.url) return

    try {
      await this.avPlayer?.reset()
      this.avPlayer!.url = current.url
      await this.avPlayer?.prepare()
      await this.avPlayer?.play()
      this.updateSessionMetadata()
    } catch (err) {
      console.error('Play failed:', err)
      this._state = PlaybackState.ERROR
    }
  }

  async pause(): Promise<void> {
    await this.avPlayer?.pause()
  }

  async resume(): Promise<void> {
    await this.avPlayer?.play()
  }

  async stop(): Promise<void> {
    await this.avPlayer?.stop()
  }

  async seekTo(position: number): Promise<void> {
    if (this.avPlayer) {
      this.avPlayer.seek(position)
    }
  }

  async skipToNext(): Promise<void> {
    if (this.repeatMode === MusicRepeatMode.SINGLE) {
      await this.seekTo(0)
      await this.play()
      return
    }

    let nextIndex = this.currentIndex + 1
    if (nextIndex >= this.playList.length) {
      nextIndex = 0
    }
    
    if (this.repeatMode === MusicRepeatMode.SHUFFLE) {
      nextIndex = Math.floor(Math.random() * this.playList.length)
    }

    this.currentIndex = nextIndex
    await this.play()
  }

  async skipToPrevious(): Promise<void> {
    let prevIndex = this.currentIndex - 1
    if (prevIndex < 0) {
      prevIndex = this.playList.length - 1
    }
    this.currentIndex = prevIndex
    await this.play()
  }

  setRepeatMode(mode: MusicRepeatMode): void {
    this.repeatMode = mode
  }

  setPlayList(list: MusicItem[], startIndex: number = 0): void {
    this.playList = [...list]
    this.currentIndex = startIndex
  }

  addToPlayList(music: MusicItem | MusicItem[]): void {
    const items = Array.isArray(music) ? music : [music]
    this.playList.push(...items)
  }

  removeFromPlayList(music: MusicItem): void {
    const index = this.findMusicIndex(music)
    if (index >= 0) {
      this.playList.splice(index, 1)
      if (index < this.currentIndex) {
        this.currentIndex--
      }
    }
  }

  private findMusicIndex(music: MusicItem): number {
    return this.playList.findIndex(
      m => m.platform === music.platform && m.id === music.id
    )
  }

  private handlePlayEnd(): void {
    this.emitEvent(PlaybackEvents.PLAY_END, {})
    this.skipToNext()
  }

  private updateSessionMetadata(): void {
    const music = this.currentMusic
    if (!music || !this.session) return

    const metadata: avSession.AVMetadata = {
      assetId: music.id,
      title: music.title,
      artist: music.artist,
      album: music.album,
      mediaImage: music.artwork,
      duration: music.duration ?? 0
    }
    this.session.setAVMetadata(metadata)
  }

  private emitEvent(eventId: string, data: object): void {
    emitter.emit({ eventId }, { data })
  }

  async destroy(): Promise<void> {
    await this.avPlayer?.release()
    await this.session?.destroy()
    this.avPlayer = undefined
    this.session = undefined
  }
}

export const playbackService = new PlaybackService()
```

**Step 2: 创建 TrackPlayerVM.ets**
```typescript
import { playbackService, PlaybackState, PlaybackEvents } from '../service/PlaybackService'
import { MusicItem } from '../model/MusicItem'
import { MusicRepeatMode } from '../constants/CommonConst'
import { emitter } from '@kit.BasicServicesKit'

@Observed
export class TrackPlayerVM {
  currentMusic: MusicItem | null = null
  playList: MusicItem[] = []
  state: PlaybackState = PlaybackState.IDLE
  position: number = 0
  duration: number = 0
  repeatMode: MusicRepeatMode = MusicRepeatMode.QUEUE

  constructor() {
    this.setupListeners()
  }

  private setupListeners(): void {
    emitter.on({ eventId: PlaybackEvents.STATE_CHANGED }, (event) => {
      this.state = event.data?.state as PlaybackState
    })

    emitter.on({ eventId: PlaybackEvents.TRACK_CHANGED }, (event) => {
      this.currentMusic = event.data?.music as MusicItem
    })

    emitter.on({ eventId: PlaybackEvents.PROGRESS_CHANGED }, (event) => {
      this.position = event.data?.position as number ?? 0
      this.duration = event.data?.duration as number ?? 0
    })
  }

  get isPlaying(): boolean {
    return this.state === PlaybackState.PLAYING
  }

  get isPaused(): boolean {
    return this.state === PlaybackState.PAUSED
  }

  get progress(): number {
    return this.duration > 0 ? this.position / this.duration : 0
  }

  async play(music?: MusicItem): Promise<void> {
    await playbackService.play(music)
  }

  async pause(): Promise<void> {
    await playbackService.pause()
  }

  async togglePlayPause(): Promise<void> {
    if (this.isPlaying) {
      await this.pause()
    } else {
      await playbackService.resume()
    }
  }

  async skipToNext(): Promise<void> {
    await playbackService.skipToNext()
  }

  async skipToPrevious(): Promise<void> {
    await playbackService.skipToPrevious()
  }

  async seekTo(position: number): Promise<void> {
    await playbackService.seekTo(position)
  }

  toggleRepeatMode(): void {
    const modes = [MusicRepeatMode.QUEUE, MusicRepeatMode.SINGLE, MusicRepeatMode.SHUFFLE]
    const currentIndex = modes.indexOf(this.repeatMode)
    this.repeatMode = modes[(currentIndex + 1) % modes.length]
    playbackService.setRepeatMode(this.repeatMode)
  }

  setPlayList(list: MusicItem[], startIndex?: number): void {
    this.playList = list
    playbackService.setPlayList(list, startIndex)
  }
}
```

**Step 3: Commit**
```bash
git add entry/src/main/ets/service/ entry/src/main/ets/viewmodel/
git commit -m "feat: implement PlaybackService with AVPlayer and AVSession"
```

---

#### Task 2.2: 实现插件引擎

**Files:**
- Create: `commons/plugin-engine/src/main/ets/PluginEngine.ets`
- Create: `commons/plugin-engine/src/main/ets/PluginWorker.ets`
- Create: `entry/src/main/ets/viewmodel/PluginManagerVM.ets`

**关键技术点:**
- 使用 Worker 隔离执行插件 JavaScript 代码
- 实现插件生命周期管理
- 提供安全的沙箱环境

**Step 1: 创建 HAR 模块 commons/plugin-engine**

**Step 2: 创建 PluginEngine.ets**
```typescript
import { worker } from '@kit.ArkTS'
import { fileIo } from '@kit.CoreFileKit'
import { Plugin } from '../../entry/src/main/ets/model/Plugin'
import { MusicItem } from '../../entry/src/main/ets/model/MusicItem'
import { hash } from '@kit.CryptoKit'

interface PluginMethodResult {
  success: boolean
  data?: unknown
  error?: string
}

class PluginEngine {
  private plugins: Map<string, Plugin> = new Map()
  private workers: Map<string, worker.ThreadWorker> = new Map()
  private pluginDir: string = ''

  async init(sandboxPath: string): Promise<void> {
    this.pluginDir = `${sandboxPath}/plugins`
    try {
      await fileIo.mkdir(this.pluginDir)
    } catch {
      // 目录已存在
    }
    await this.loadInstalledPlugins()
  }

  private async loadInstalledPlugins(): Promise<void> {
    try {
      const files = await fileIo.listFile(this.pluginDir)
      for (const file of files) {
        if (file.endsWith('.js')) {
          await this.loadPlugin(`${this.pluginDir}/${file}`)
        }
      }
    } catch (err) {
      console.error('Load plugins failed:', err)
    }
  }

  async installPluginFromUrl(url: string): Promise<Plugin | null> {
    try {
      // 下载插件
      const response = await fetch(url)
      const code = await response.text()
      return await this.installPlugin(code, url)
    } catch (err) {
      console.error('Install plugin from URL failed:', err)
      return null
    }
  }

  async installPluginFromFile(filePath: string): Promise<Plugin | null> {
    try {
      const file = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY)
      const stat = await fileIo.stat(filePath)
      const buffer = new ArrayBuffer(stat.size)
      await fileIo.read(file.fd, buffer)
      await fileIo.close(file)
      
      const code = String.fromCharCode(...new Uint8Array(buffer))
      return await this.installPlugin(code)
    } catch (err) {
      console.error('Install plugin from file failed:', err)
      return null
    }
  }

  private async installPlugin(code: string, srcUrl?: string): Promise<Plugin | null> {
    // 计算哈希
    const hashValue = await this.calculateHash(code)
    
    // 解析插件元信息
    const pluginInfo = this.parsePluginInfo(code)
    if (!pluginInfo) return null

    const plugin = new Plugin()
    plugin.platform = pluginInfo.platform
    plugin.name = pluginInfo.platform
    plugin.version = pluginInfo.version
    plugin.author = pluginInfo.author
    plugin.description = pluginInfo.description
    plugin.srcUrl = srcUrl
    plugin.hash = hashValue
    plugin.hasSearch = code.includes('search')
    plugin.hasGetMediaSource = code.includes('getMediaSource')
    plugin.hasGetLyric = code.includes('getLyric')
    plugin.hasGetAlbumInfo = code.includes('getAlbumInfo')
    plugin.hasGetArtistWorks = code.includes('getArtistWorks')
    plugin.hasGetTopLists = code.includes('getTopLists')
    plugin.hasGetRecommendSheets = code.includes('getRecommendSheetTags')

    // 保存插件文件
    const pluginPath = `${this.pluginDir}/${hashValue}.js`
    const file = await fileIo.open(pluginPath, 
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
    await fileIo.write(file.fd, code)
    await fileIo.close(file)

    // 创建 Worker
    await this.createWorkerForPlugin(plugin, pluginPath)
    this.plugins.set(hashValue, plugin)

    return plugin
  }

  private parsePluginInfo(code: string): { platform: string; version?: string; author?: string; description?: string } | null {
    // 简单解析，实际应使用更健壮的方式
    const platformMatch = code.match(/platform\s*[:=]\s*['"]([^'"]+)['"]/)
    if (!platformMatch) return null

    return {
      platform: platformMatch[1],
      version: code.match(/version\s*[:=]\s*['"]([^'"]+)['"]/)?.[1],
      author: code.match(/author\s*[:=]\s*['"]([^'"]+)['"]/)?.[1],
      description: code.match(/description\s*[:=]\s*['"]([^'"]+)['"]/)?.[1]
    }
  }

  private async calculateHash(content: string): Promise<string> {
    const encoder = new TextEncoder()
    const data = encoder.encode(content)
    const hashResult = await hash.digest('SHA-256', { data })
    return Array.from(new Uint8Array(hashResult.data))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')
      .slice(0, 32)
  }

  private async createWorkerForPlugin(plugin: Plugin, scriptPath: string): Promise<void> {
    const workerInstance = new worker.ThreadWorker(scriptPath)
    
    workerInstance.onmessage = (e) => {
      // 处理来自 Worker 的消息
      console.info('Plugin worker message:', e.data)
    }

    workerInstance.onerror = (e) => {
      console.error('Plugin worker error:', e.message)
    }

    this.workers.set(plugin.hash, workerInstance)
  }

  async callPluginMethod(
    pluginHash: string,
    method: string,
    ...args: unknown[]
  ): Promise<PluginMethodResult> {
    const workerInstance = this.workers.get(pluginHash)
    if (!workerInstance) {
      return { success: false, error: 'Plugin not found' }
    }

    return new Promise((resolve) => {
      const messageId = Date.now().toString()
      
      const handler = (e: MessageEvents) => {
        if (e.data.messageId === messageId) {
          workerInstance.off('message', handler)
          resolve(e.data.result)
        }
      }
      
      workerInstance.on('message', handler)
      workerInstance.postMessage({
        messageId,
        method,
        args
      })

      // 超时处理
      setTimeout(() => {
        workerInstance.off('message', handler)
        resolve({ success: false, error: 'Timeout' })
      }, 30000)
    })
  }

  // 搜索音乐
  async search(
    pluginHash: string,
    query: string,
    page: number,
    type: 'music' | 'album' | 'artist' | 'sheet'
  ): Promise<MusicItem[] | null> {
    const result = await this.callPluginMethod(pluginHash, 'search', query, page, type)
    return result.success ? result.data as MusicItem[] : null
  }

  // 获取播放源
  async getMediaSource(
    pluginHash: string,
    music: MusicItem,
    quality: string
  ): Promise<{ url: string; headers?: Record<string, string> } | null> {
    const result = await this.callPluginMethod(pluginHash, 'getMediaSource', music, quality)
    return result.success ? result.data as { url: string } : null
  }

  // 获取歌词
  async getLyric(
    pluginHash: string,
    music: MusicItem
  ): Promise<{ lrc?: string; tlyric?: string } | null> {
    const result = await this.callPluginMethod(pluginHash, 'getLyric', music)
    return result.success ? result.data as { lrc?: string } : null
  }

  getPlugin(hash: string): Plugin | undefined {
    return this.plugins.get(hash)
  }

  getPluginByPlatform(platform: string): Plugin | undefined {
    for (const plugin of this.plugins.values()) {
      if (plugin.platform === platform) {
        return plugin
      }
    }
    return undefined
  }

  getAllPlugins(): Plugin[] {
    return Array.from(this.plugins.values())
  }

  getEnabledPlugins(): Plugin[] {
    return this.getAllPlugins().filter(p => p.enabled)
  }

  async uninstallPlugin(hash: string): Promise<boolean> {
    const plugin = this.plugins.get(hash)
    if (!plugin) return false

    // 终止 Worker
    const workerInstance = this.workers.get(hash)
    workerInstance?.terminate()
    this.workers.delete(hash)

    // 删除文件
    try {
      await fileIo.unlink(`${this.pluginDir}/${hash}.js`)
    } catch {
      // 忽略错误
    }

    this.plugins.delete(hash)
    return true
  }

  setPluginEnabled(hash: string, enabled: boolean): void {
    const plugin = this.plugins.get(hash)
    if (plugin) {
      plugin.enabled = enabled
    }
  }

  async destroy(): Promise<void> {
    for (const workerInstance of this.workers.values()) {
      workerInstance.terminate()
    }
    this.workers.clear()
    this.plugins.clear()
  }
}

export const pluginEngine = new PluginEngine()
```

**Step 3: Commit**
```bash
git add commons/plugin-engine/
git commit -m "feat: implement plugin engine with Worker isolation"
```

---

#### Task 2.3: 实现歌单管理服务

**Files:**
- Create: `entry/src/main/ets/service/MusicSheetService.ets`
- Create: `entry/src/main/ets/viewmodel/MusicSheetVM.ets`

**Step 1: 创建 MusicSheetService.ets**
```typescript
import { relationalStore } from '@kit.ArkData'
import { MusicSheet } from '../model/MusicSheet'
import { MusicItem } from '../model/MusicItem'
import { Context } from '@kit.AbilityKit'

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'musicfree.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

const SQL_CREATE_SHEETS = `
  CREATE TABLE IF NOT EXISTS sheets (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    cover_img TEXT,
    create_at INTEGER,
    update_at INTEGER
  )
`

const SQL_CREATE_SHEET_MUSIC = `
  CREATE TABLE IF NOT EXISTS sheet_music (
    sheet_id TEXT NOT NULL,
    music_id TEXT NOT NULL,
    music_platform TEXT NOT NULL,
    music_data TEXT NOT NULL,
    sort_index INTEGER,
    PRIMARY KEY (sheet_id, music_id, music_platform)
  )
`

class MusicSheetService {
  private rdbStore?: relationalStore.RdbStore

  async init(context: Context): Promise<void> {
    this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
    await this.rdbStore.executeSql(SQL_CREATE_SHEETS)
    await this.rdbStore.executeSql(SQL_CREATE_SHEET_MUSIC)
  }

  async createSheet(title: string, description?: string): Promise<MusicSheet> {
    const sheet = new MusicSheet({
      id: this.generateId(),
      title,
      description,
      createAt: Date.now(),
      updateAt: Date.now()
    })

    const values: relationalStore.ValuesBucket = {
      id: sheet.id,
      title: sheet.title,
      description: sheet.description ?? '',
      cover_img: sheet.coverImg ?? '',
      create_at: sheet.createAt,
      update_at: sheet.updateAt
    }

    await this.rdbStore?.insert('sheets', values)
    return sheet
  }

  async getAllSheets(): Promise<MusicSheet[]> {
    const predicates = new relationalStore.RdbPredicates('sheets')
    const resultSet = await this.rdbStore?.query(predicates)
    
    const sheets: MusicSheet[] = []
    while (resultSet?.goToNextRow()) {
      sheets.push(new MusicSheet({
        id: resultSet.getString(resultSet.getColumnIndex('id')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        description: resultSet.getString(resultSet.getColumnIndex('description')),
        coverImg: resultSet.getString(resultSet.getColumnIndex('cover_img')),
        createAt: resultSet.getLong(resultSet.getColumnIndex('create_at')),
        updateAt: resultSet.getLong(resultSet.getColumnIndex('update_at'))
      }))
    }
    resultSet?.close()
    return sheets
  }

  async getSheetWithMusic(sheetId: string): Promise<MusicSheet | null> {
    // 获取歌单信息
    const predicates = new relationalStore.RdbPredicates('sheets')
    predicates.equalTo('id', sheetId)
    const resultSet = await this.rdbStore?.query(predicates)
    
    if (!resultSet?.goToNextRow()) {
      resultSet?.close()
      return null
    }

    const sheet = new MusicSheet({
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      title: resultSet.getString(resultSet.getColumnIndex('title')),
      description: resultSet.getString(resultSet.getColumnIndex('description')),
      coverImg: resultSet.getString(resultSet.getColumnIndex('cover_img')),
      createAt: resultSet.getLong(resultSet.getColumnIndex('create_at')),
      updateAt: resultSet.getLong(resultSet.getColumnIndex('update_at'))
    })
    resultSet?.close()

    // 获取歌单中的音乐
    sheet.musicList = await this.getSheetMusic(sheetId)
    return sheet
  }

  async getSheetMusic(sheetId: string): Promise<MusicItem[]> {
    const predicates = new relationalStore.RdbPredicates('sheet_music')
    predicates.equalTo('sheet_id', sheetId)
    predicates.orderByAsc('sort_index')
    
    const resultSet = await this.rdbStore?.query(predicates)
    const musicList: MusicItem[] = []

    while (resultSet?.goToNextRow()) {
      const musicData = resultSet.getString(resultSet.getColumnIndex('music_data'))
      try {
        const parsed = JSON.parse(musicData) as MusicItem
        musicList.push(new MusicItem(parsed))
      } catch {
        // 解析失败跳过
      }
    }
    resultSet?.close()
    return musicList
  }

  async addMusicToSheet(sheetId: string, music: MusicItem | MusicItem[]): Promise<void> {
    const items = Array.isArray(music) ? music : [music]
    const existingMusic = await this.getSheetMusic(sheetId)
    let sortIndex = existingMusic.length

    for (const item of items) {
      // 检查是否已存在
      const exists = existingMusic.some(
        m => m.id === item.id && m.platform === item.platform
      )
      if (exists) continue

      const values: relationalStore.ValuesBucket = {
        sheet_id: sheetId,
        music_id: item.id,
        music_platform: item.platform,
        music_data: JSON.stringify(item),
        sort_index: sortIndex++
      }
      await this.rdbStore?.insert('sheet_music', values)
    }

    // 更新歌单修改时间
    await this.updateSheetTime(sheetId)
  }

  async removeMusicFromSheet(sheetId: string, music: MusicItem): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('sheet_music')
    predicates.equalTo('sheet_id', sheetId)
    predicates.equalTo('music_id', music.id)
    predicates.equalTo('music_platform', music.platform)
    
    await this.rdbStore?.delete(predicates)
    await this.updateSheetTime(sheetId)
  }

  async deleteSheet(sheetId: string): Promise<void> {
    // 删除歌单中的音乐
    const musicPredicates = new relationalStore.RdbPredicates('sheet_music')
    musicPredicates.equalTo('sheet_id', sheetId)
    await this.rdbStore?.delete(musicPredicates)

    // 删除歌单
    const sheetPredicates = new relationalStore.RdbPredicates('sheets')
    sheetPredicates.equalTo('id', sheetId)
    await this.rdbStore?.delete(sheetPredicates)
  }

  async updateSheet(sheetId: string, updates: Partial<MusicSheet>): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      update_at: Date.now()
    }
    if (updates.title !== undefined) values.title = updates.title
    if (updates.description !== undefined) values.description = updates.description
    if (updates.coverImg !== undefined) values.cover_img = updates.coverImg

    const predicates = new relationalStore.RdbPredicates('sheets')
    predicates.equalTo('id', sheetId)
    await this.rdbStore?.update(values, predicates)
  }

  private async updateSheetTime(sheetId: string): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      update_at: Date.now()
    }
    const predicates = new relationalStore.RdbPredicates('sheets')
    predicates.equalTo('id', sheetId)
    await this.rdbStore?.update(values, predicates)
  }

  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 9)
  }
}

export const musicSheetService = new MusicSheetService()
```

**Step 2: Commit**
```bash
git add entry/src/main/ets/service/MusicSheetService.ets
git commit -m "feat: implement music sheet service with RDB storage"
```

---

### Phase 3: UI 组件层 (预计 7-10 天)

#### Task 3.1: 实现基础组件

**Files:**
- Create: `entry/src/main/ets/components/base/AppBar.ets`
- Create: `entry/src/main/ets/components/base/IconButton.ets`
- Create: `entry/src/main/ets/components/base/MusicImage.ets`
- Create: `entry/src/main/ets/components/base/Empty.ets`
- Create: `entry/src/main/ets/components/base/Chip.ets`

**Step 1: 创建 AppBar.ets**
```typescript
@Component
export struct AppBar {
  @Prop title: string = ''
  @Prop showBack: boolean = true
  onBackPress?: () => void
  @BuilderParam rightContent?: () => void

  build() {
    Row() {
      if (this.showBack) {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            this.onBackPress?.()
          })
      }

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)

      if (this.rightContent) {
        this.rightContent()
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.background'))
  }
}
```

**Step 2: 创建 MusicImage.ets**
```typescript
@Component
export struct MusicImage {
  @Prop src: string = ''
  @Prop size: number = 48
  @Prop radius: number = 8

  build() {
    if (this.src) {
      Image(this.src)
        .width(this.size)
        .height(this.size)
        .borderRadius(this.radius)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.album_default'))
    } else {
      Image($r('app.media.album_default'))
        .width(this.size)
        .height(this.size)
        .borderRadius(this.radius)
        .objectFit(ImageFit.Cover)
    }
  }
}
```

**Step 3: 创建 IconButton.ets**
```typescript
@Component
export struct IconButton {
  @Prop icon: Resource
  @Prop size: number = 24
  @Prop color: ResourceColor = $r('app.color.text_primary')
  onClick?: () => void

  build() {
    Button({ type: ButtonType.Circle }) {
      Image(this.icon)
        .width(this.size)
        .height(this.size)
        .fillColor(this.color)
    }
    .width(this.size + 16)
    .height(this.size + 16)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.onClick?.()
    })
  }
}
```

**Step 4: Commit**
```bash
git add entry/src/main/ets/components/base/
git commit -m "feat: add base UI components (AppBar, IconButton, MusicImage)"
```

---

#### Task 3.2: 实现音乐列表组件

**Files:**
- Create: `entry/src/main/ets/components/music/MusicItem.ets`
- Create: `entry/src/main/ets/components/music/MusicList.ets`
- Create: `entry/src/main/ets/components/music/MusicBar.ets`

**Step 1: 创建 MusicItem.ets (列表项组件)**
```typescript
import { MusicItem as MusicItemModel } from '../../model/MusicItem'
import { MusicImage } from '../base/MusicImage'

@Component
export struct MusicItemView {
  @ObjectLink music: MusicItemModel
  @Prop isPlaying: boolean = false
  onPress?: (music: MusicItemModel) => void
  onMorePress?: (music: MusicItemModel) => void

  build() {
    Row() {
      MusicImage({ src: this.music.artwork ?? '', size: 48 })

      Column() {
        Text(this.music.title)
          .fontSize(16)
          .fontColor(this.isPlaying ? $r('app.color.primary') : $r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.music.artist)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Image($r('app.media.ic_more'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_secondary'))
        .onClick(() => {
          this.onMorePress?.(this.music)
        })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      this.onPress?.(this.music)
    })
  }
}
```

**Step 2: 创建 MusicList.ets**
```typescript
import { MusicItem as MusicItemModel } from '../../model/MusicItem'
import { MusicItemView } from './MusicItem'

@Component
export struct MusicList {
  @ObjectLink musicList: MusicItemModel[]
  @Prop currentMusicId: string = ''
  @Prop currentPlatform: string = ''
  onItemPress?: (music: MusicItemModel, index: number) => void
  onItemMorePress?: (music: MusicItemModel) => void

  build() {
    List() {
      ForEach(this.musicList, (item: MusicItemModel, index: number) => {
        ListItem() {
          MusicItemView({
            music: item,
            isPlaying: item.id === this.currentMusicId && item.platform === this.currentPlatform,
            onPress: (music) => {
              this.onItemPress?.(music, index)
            },
            onMorePress: this.onItemMorePress
          })
        }
      }, (item: MusicItemModel) => `${item.platform}@${item.id}`)
    }
    .width('100%')
    .layoutWeight(1)
    .divider({
      strokeWidth: 0.5,
      color: $r('app.color.divider'),
      startMargin: 76,
      endMargin: 16
    })
  }
}
```

**Step 3: 创建 MusicBar.ets (底部播放栏)**
```typescript
import { MusicItem as MusicItemModel } from '../../model/MusicItem'
import { MusicImage } from '../base/MusicImage'
import { IconButton } from '../base/IconButton'
import { TrackPlayerVM } from '../../viewmodel/TrackPlayerVM'

@Component
export struct MusicBar {
  @ObjectLink playerVM: TrackPlayerVM
  onPress?: () => void

  build() {
    if (this.playerVM.currentMusic) {
      Row() {
        MusicImage({
          src: this.playerVM.currentMusic.artwork ?? '',
          size: 48,
          radius: 24
        })

        Column() {
          Text(this.playerVM.currentMusic.title)
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.playerVM.currentMusic.artist)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })

        IconButton({
          icon: this.playerVM.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'),
          size: 28,
          onClick: () => {
            this.playerVM.togglePlayPause()
          }
        })

        IconButton({
          icon: $r('app.media.ic_skip_next'),
          size: 24,
          onClick: () => {
            this.playerVM.skipToNext()
          }
        })
        .margin({ left: 8 })
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.surface'))
      .shadow({
        radius: 8,
        color: '#1A000000',
        offsetY: -2
      })
      .onClick(() => {
        this.onPress?.()
      })
    }
  }
}
```

**Step 4: Commit**
```bash
git add entry/src/main/ets/components/music/
git commit -m "feat: add music components (MusicItem, MusicList, MusicBar)"
```

---

#### Task 3.3: 实现首页

**Files:**
- Create: `entry/src/main/ets/pages/Home.ets`
- Create: `entry/src/main/ets/pages/Index.ets`

**Step 1: 创建 Home.ets**
```typescript
import { MusicSheet } from '../model/MusicSheet'
import { MusicSheetVM } from '../viewmodel/MusicSheetVM'
import { TrackPlayerVM } from '../viewmodel/TrackPlayerVM'
import { MusicBar } from '../components/music/MusicBar'
import { MusicImage } from '../components/base/MusicImage'
import { RouteConst } from '../constants/RouteConst'

@Entry
@Component
struct Home {
  @StorageLink('trackPlayerVM') playerVM: TrackPlayerVM = new TrackPlayerVM()
  @State sheetVM: MusicSheetVM = new MusicSheetVM()
  @State sheets: MusicSheet[] = []
  private navPathStack: NavPathStack = new NavPathStack()

  aboutToAppear() {
    this.loadSheets()
  }

  async loadSheets() {
    this.sheets = await this.sheetVM.getAllSheets()
  }

  @Builder
  SheetItem(sheet: MusicSheet) {
    Row() {
      MusicImage({ src: sheet.coverImg ?? '', size: 56, radius: 8 })

      Column() {
        Text(sheet.title)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))

        Text(`${sheet.musicList.length} 首`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Image($r('app.media.ic_arrow_right'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.text_hint'))
    }
    .width('100%')
    .padding(16)
    .onClick(() => {
      this.navPathStack.pushPathByName(RouteConst.LOCAL_SHEET_DETAIL, { sheetId: sheet.id })
    })
  }

  build() {
    Navigation(this.navPathStack) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          // 顶部栏
          Row() {
            Text('MusicFree')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))

            Blank()

            Image($r('app.media.ic_search'))
              .width(24)
              .height(24)
              .margin({ right: 16 })
              .onClick(() => {
                this.navPathStack.pushPathByName(RouteConst.SEARCH, {})
              })

            Image($r('app.media.ic_settings'))
              .width(24)
              .height(24)
              .onClick(() => {
                this.navPathStack.pushPathByName(RouteConst.SETTING, {})
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 8 })

          // 快捷入口
          Row() {
            this.QuickEntry($r('app.media.ic_local_music'), '本地音乐', () => {
              this.navPathStack.pushPathByName(RouteConst.LOCAL_MUSIC, {})
            })
            this.QuickEntry($r('app.media.ic_history'), '播放历史', () => {
              this.navPathStack.pushPathByName(RouteConst.HISTORY, {})
            })
            this.QuickEntry($r('app.media.ic_download'), '下载管理', () => {
              this.navPathStack.pushPathByName(RouteConst.DOWNLOADING, {})
            })
            this.QuickEntry($r('app.media.ic_ranking'), '排行榜', () => {
              this.navPathStack.pushPathByName(RouteConst.TOP_LIST, {})
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .padding({ top: 16, bottom: 16 })

          // 我的歌单
          Row() {
            Text('我的歌单')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))

            Blank()

            Image($r('app.media.ic_add'))
              .width(24)
              .height(24)
              .onClick(() => {
                this.showCreateSheetDialog()
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

          // 歌单列表
          List() {
            ForEach(this.sheets, (sheet: MusicSheet) => {
              ListItem() {
                this.SheetItem(sheet)
              }
            }, (sheet: MusicSheet) => sheet.id)
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .height('100%')

        // 底部播放栏
        MusicBar({
          playerVM: this.playerVM,
          onPress: () => {
            this.navPathStack.pushPathByName(RouteConst.MUSIC_DETAIL, {})
          }
        })
      }
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }

  @Builder
  QuickEntry(icon: Resource, title: string, onClick: () => void) {
    Column() {
      Image(icon)
        .width(32)
        .height(32)
        .fillColor($r('app.color.primary'))

      Text(title)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .onClick(onClick)
  }

  showCreateSheetDialog() {
    // TODO: 实现创建歌单对话框
  }
}
```

**Step 2: Commit**
```bash
git add entry/src/main/ets/pages/Home.ets
git commit -m "feat: implement Home page with navigation"
```

---

#### Task 3.4: 实现播放详情页

**Files:**
- Create: `entry/src/main/ets/pages/MusicDetail.ets`

**Step 1: 创建 MusicDetail.ets**
```typescript
import { TrackPlayerVM } from '../viewmodel/TrackPlayerVM'
import { MusicImage } from '../components/base/MusicImage'
import { IconButton } from '../components/base/IconButton'
import { MusicRepeatMode } from '../constants/CommonConst'

@Entry
@Component
struct MusicDetail {
  @StorageLink('trackPlayerVM') playerVM: TrackPlayerVM = new TrackPlayerVM()
  @State showLyric: boolean = false
  private navPathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          IconButton({
            icon: $r('app.media.ic_arrow_down'),
            onClick: () => {
              this.navPathStack.pop()
            }
          })

          Blank()

          Text(this.playerVM.currentMusic?.title ?? '未在播放')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank()

          IconButton({
            icon: $r('app.media.ic_more'),
            onClick: () => {
              // TODO: 显示更多菜单
            }
          })
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 16 })

        // 封面/歌词切换区域
        Column() {
          if (this.showLyric) {
            // TODO: 歌词组件
            Text('歌词显示区域')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          } else {
            MusicImage({
              src: this.playerVM.currentMusic?.artwork ?? '',
              size: 280,
              radius: 16
            })
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showLyric = !this.showLyric
        })

        // 歌曲信息
        Column() {
          Text(this.playerVM.currentMusic?.title ?? '')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.playerVM.currentMusic?.artist ?? '')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ left: 32, right: 32 })
        .margin({ bottom: 24 })

        // 进度条
        Column() {
          Slider({
            value: this.playerVM.progress * 100,
            min: 0,
            max: 100,
            style: SliderStyle.OutSet
          })
            .selectedColor($r('app.color.primary'))
            .trackColor($r('app.color.divider'))
            .onChange((value: number) => {
              const position = (value / 100) * this.playerVM.duration
              this.playerVM.seekTo(position)
            })

          Row() {
            Text(this.formatTime(this.playerVM.position))
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))

            Blank()

            Text(this.formatTime(this.playerVM.duration))
              .fontSize(12)
              .fontColor($r('app.color.text_hint'))
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 24, right: 24 })

        // 控制按钮
        Row() {
          IconButton({
            icon: this.getRepeatModeIcon(),
            size: 24,
            onClick: () => {
              this.playerVM.toggleRepeatMode()
            }
          })

          IconButton({
            icon: $r('app.media.ic_skip_previous'),
            size: 32,
            onClick: () => {
              this.playerVM.skipToPrevious()
            }
          })

          Button({ type: ButtonType.Circle }) {
            Image(this.playerVM.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
              .width(32)
              .height(32)
              .fillColor(Color.White)
          }
          .width(64)
          .height(64)
          .backgroundColor($r('app.color.primary'))
          .margin({ left: 24, right: 24 })
          .onClick(() => {
            this.playerVM.togglePlayPause()
          })

          IconButton({
            icon: $r('app.media.ic_skip_next'),
            size: 32,
            onClick: () => {
              this.playerVM.skipToNext()
            }
          })

          IconButton({
            icon: $r('app.media.ic_playlist'),
            size: 24,
            onClick: () => {
              // TODO: 显示播放列表
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: 24, bottom: 48 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background'))
    }
    .hideTitleBar(true)
  }

  getRepeatModeIcon(): Resource {
    switch (this.playerVM.repeatMode) {
      case MusicRepeatMode.SINGLE:
        return $r('app.media.ic_repeat_one')
      case MusicRepeatMode.SHUFFLE:
        return $r('app.media.ic_shuffle')
      default:
        return $r('app.media.ic_repeat')
    }
  }

  formatTime(ms: number): string {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const remainSeconds = seconds % 60
    return `${minutes.toString().padStart(2, '0')}:${remainSeconds.toString().padStart(2, '0')}`
  }
}
```

**Step 2: Commit**
```bash
git add entry/src/main/ets/pages/MusicDetail.ets
git commit -m "feat: implement MusicDetail page with playback controls"
```

---

### Phase 4: 其他页面与完善 (预计 5-7 天)

#### Task 4.1: 实现搜索页面
#### Task 4.2: 实现设置页面
#### Task 4.3: 实现歌单详情页
#### Task 4.4: 实现本地音乐页面
#### Task 4.5: 实现下载管理页面
#### Task 4.6: 实现播放历史页面
#### Task 4.7: 实现排行榜页面

*(每个页面按照类似 Task 3.3/3.4 的模式实现)*

---

### Phase 5: 测试与优化 (预计 3-5 天)

#### Task 5.1: 编写单元测试
#### Task 5.2: 编写 UI 测试
#### Task 5.3: 性能优化
#### Task 5.4: 适配多设备 (手机/平板/折叠屏)

---

## 五、技术要点总结

### 5.1 React Native → ArkTS 映射表

| React Native | ArkTS/ArkUI |
|--------------|-------------|
| `useState` | `@State` |
| `useContext` | `@StorageLink` / `@Provide/@Consume` |
| `useMemo` | `@Computed` (需手动实现) |
| `useEffect` | `aboutToAppear()` / `aboutToDisappear()` |
| `useCallback` | 普通方法 |
| `ScrollView` | `Scroll` |
| `FlatList` | `List` + `ForEach` |
| `TouchableOpacity` | `.onClick()` |
| `StyleSheet` | 内联样式或 `@Styles` |
| `Navigation` | `Navigation` + `NavDestination` |
| `Modal` | `CustomDialogController` |
| `TextInput` | `TextInput` |
| `Image` | `Image` |
| `View` | `Column` / `Row` / `Stack` |
| `Text` | `Text` |

### 5.2 关键 API 对照

| 功能 | React Native | HarmonyOS 6 |
|------|--------------|-------------|
| 音频播放 | react-native-track-player | @ohos.multimedia.media (AVPlayer) |
| 后台播放 | Background Service | AVSession + BackgroundTaskManager |
| 本地存储 | MMKV / AsyncStorage | preferences / @aspect/mmkv |
| 数据库 | SQLite | relationalStore (RDB) |
| 网络请求 | Axios | @ohos/axios / @ohos.net.http |
| 文件操作 | react-native-fs | @ohos.file.fs |
| 权限 | react-native-permissions | @ohos.abilityAccessCtrl |
| 线程 | - | Worker |

---

## 六、风险与挑战

1. **插件系统兼容性**: 现有 JS 插件需要适配 Worker 环境运行
2. **音频格式支持**: 需要验证 AVPlayer 对各种音频格式的支持
3. **后台播放稳定性**: HarmonyOS 的后台限制可能影响长时间播放
4. **UI 一致性**: ArkUI 与 React Native 的 UI 范式差异较大
5. **性能调优**: 大列表、频繁状态更新需要优化

---

## 七、时间估算

| 阶段 | 预计时间 |
|------|---------|
| Phase 1: 项目基础搭建 | 2 天 |
| Phase 2: 核心服务层 | 5-7 天 |
| Phase 3: UI 组件层 | 7-10 天 |
| Phase 4: 其他页面 | 5-7 天 |
| Phase 5: 测试优化 | 3-5 天 |
| **总计** | **22-31 天** |

---

*最后更新: 2026-04-20*
