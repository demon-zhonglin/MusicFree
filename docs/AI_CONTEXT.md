# MusicFree AI 上下文文档

> 本文档旨在帮助 AI 工具快速理解项目结构和代码规范，适用于 Cursor、GitHub Copilot、Claude、ChatGPT 等 AI 编程助手。

## 项目概述

**MusicFree** 是一个插件化、定制化、无广告的免费音乐播放器。

| 属性 | 值 |
|------|-----|
| 版本 | 0.6.2 |
| 许可证 | AGPL-3.0 |
| 作者 | 猫头猫 |
| 仓库 | https://github.com/maotoumao/MusicFree |
| 平台 | Android, Harmony OS |

## 技术栈

- **框架**: React Native 0.76.5 + React 18.3.1
- **语言**: TypeScript
- **状态管理**: Jotai
- **导航**: React Navigation 6 (native-stack)
- **音频播放**: react-native-track-player
- **本地存储**: MMKV
- **部分原生功能**: Expo

## 架构设计

### 核心理念

MusicFree 采用**插件化架构**，将播放器核心功能与音源完全分离：

```
用户操作 → UI组件 → Core服务层 → 插件系统 → 数据持久化(MMKV/文件系统)
```

### 设计模式

1. **依赖注入模式** - 通过 `IInjectable` 接口和 `injectDependencies` 方法注入依赖
2. **事件驱动模式** - 使用 `EventEmitter` 处理异步事件
3. **原子化状态管理** - 使用 Jotai Atoms 管理全局状态
4. **单例模式** - 核心服务类均为单例

### 依赖注入链

```
PluginManager ← Config
MusicHistory ← Config
TrackPlayer ← Config, MusicHistory, PluginManager
Downloader ← Config, PluginManager
LyricManager ← TrackPlayer, Config, PluginManager
MusicSheet ← Config
```

## 目录结构

```
src/
├── core/                    # 核心业务逻辑层
│   ├── appConfig.ts         # 应用配置管理
│   ├── trackPlayer/         # 音乐播放控制器
│   ├── pluginManager/       # 插件管理器
│   ├── musicSheet/          # 歌单管理
│   ├── lyricManager.ts      # 歌词管理器
│   ├── downloader.ts        # 下载管理器
│   ├── musicHistory.ts      # 播放历史
│   ├── localMusicSheet.ts   # 本地音乐
│   ├── theme.ts             # 主题管理
│   └── i18n/                # 国际化
├── pages/                   # 页面组件 (19个页面)
│   ├── home/                # 首页
│   ├── musicDetail/         # 播放详情页
│   ├── searchPage/          # 搜索页面
│   ├── setting/             # 设置页面
│   ├── topList/             # 排行榜
│   ├── albumDetail/         # 专辑详情
│   ├── artistDetail/        # 艺术家详情
│   └── ...
├── components/              # 可复用组件
│   ├── base/                # 基础UI组件
│   ├── dialogs/             # 对话框组件
│   ├── panels/              # 面板组件
│   ├── mediaItem/           # 媒体项组件
│   ├── musicBar/            # 底部播放栏
│   └── musicList/           # 音乐列表
├── types/                   # TypeScript 类型定义
│   ├── music.d.ts           # 音乐类型
│   ├── plugin.d.ts          # 插件接口
│   ├── album.d.ts           # 专辑类型
│   ├── artist.d.ts          # 艺术家类型
│   ├── musicSheet.d.ts      # 歌单类型
│   └── lyric.d.ts           # 歌词类型
├── utils/                   # 工具函数
├── hooks/                   # 自定义Hooks
├── constants/               # 常量定义
├── native/                  # 原生模块桥接
├── entry/                   # 应用入口
│   ├── index.tsx            # React组件入口
│   └── bootstrap/           # 启动引导
└── assets/                  # 静态资源
```

## 核心模块详解

### 1. TrackPlayer (播放控制器)

**文件**: `src/core/trackPlayer/index.ts`

主要功能：
- 管理播放列表 (`playList`)
- 控制播放状态 (播放/暂停/上一首/下一首)
- 切换播放模式 (单曲循环/列表循环/随机播放)
- 切换音质
- 进度控制

关键属性：
```typescript
currentMusic: IMusic.IMusicItem | null  // 当前播放歌曲
previousMusic: IMusic.IMusicItem | null // 上一首
nextMusic: IMusic.IMusicItem | null     // 下一首
playList: IMusic.IMusicItem[]           // 播放列表
repeatMode: MusicRepeatMode             // 播放模式
quality: IMusic.IQualityKey             // 当前音质
```

### 2. PluginManager (插件管理器)

**文件**: `src/core/pluginManager/index.ts`

主要功能：
- 安装/卸载/更新插件
- 启用/禁用插件
- 管理插件顺序
- 管理用户变量

关键方法：
```typescript
installPluginFromLocalFile(path, options)
installPluginFromUrl(url, options)
uninstallPlugin(hash)
getByMedia(mediaItem)
getEnabledPlugins()
getSortedPlugins()
```

### 3. MusicSheet (歌单管理)

**文件**: `src/core/musicSheet/index.ts`

主要功能：
- 歌单 CRUD 操作
- 向歌单添加/移除音乐
- 歌单排序
- 收藏远程歌单
- 备份/恢复歌单

### 4. LyricManager (歌词管理)

**文件**: `src/core/lyricManager.ts`

主要功能：
- 获取在线歌词
- 上传本地歌词
- 歌词关联
- 歌词偏移调整

## 插件系统

### 插件接口 (IPluginDefine)

**文件**: `src/types/plugin.d.ts`

```typescript
interface IPluginDefine {
  // 必填
  platform: string;                    // 插件名称/来源
  
  // 可选配置
  version?: string;                    // 插件版本
  srcUrl?: string;                     // 远程更新URL
  author?: string;                     // 插件作者
  description?: string;                // 插件描述
  userVariables?: IUserVariable[];     // 用户自定义变量
  
  // 可选方法
  search?: ISearchFunc;                // 搜索音乐/专辑/作者
  getMediaSource?: (...) => Promise;   // 获取播放源
  getMusicInfo?: (...) => Promise;     // 获取音乐详情
  getLyric?: (...) => Promise;         // 获取歌词
  getAlbumInfo?: (...) => Promise;     // 获取专辑信息
  getMusicSheetInfo?: (...) => Promise;// 获取歌单信息
  getArtistWorks?: (...) => Promise;   // 获取艺术家作品
  importMusicSheet?: (...) => Promise; // 导入歌单
  importMusicItem?: (...) => Promise;  // 导入单曲
  getTopLists?: (...) => Promise;      // 获取排行榜
  getRecommendSheetTags?: (...) => Promise; // 获取推荐歌单标签
  getMusicComments?: (...) => Promise; // 获取评论
}
```

## 路由配置

**导航库**: `@react-navigation/native-stack`

| 路由路径 | 组件 | 描述 |
|---------|------|------|
| HOME | Home | 首页 |
| MUSIC_DETAIL | MusicDetail | 播放详情 |
| SEARCH_PAGE | SearchPage | 搜索 |
| SETTING | Setting | 设置 |
| TOP_LIST | TopList | 排行榜 |
| TOP_LIST_DETAIL | TopListDetail | 排行榜详情 |
| ALBUM_DETAIL | AlbumDetail | 专辑详情 |
| ARTIST_DETAIL | ArtistDetail | 艺术家详情 |
| LOCAL_SHEET_DETAIL | SheetDetail | 本地歌单详情 |
| PLUGIN_SHEET_DETAIL | PluginSheetDetail | 插件歌单详情 |
| LOCAL | LocalMusic | 本地音乐 |
| DOWNLOADING | Downloading | 下载管理 |
| HISTORY | History | 播放历史 |
| RECOMMEND_SHEETS | RecommendSheets | 推荐歌单 |
| FILE_SELECTOR | FileSelector | 文件选择 |
| MUSIC_LIST_EDITOR | MusicListEditor | 歌单编辑 |
| SEARCH_MUSIC_LIST | SearchMusicList | 歌单搜索 |
| SET_CUSTOM_THEME | SetCustomTheme | 自定义主题 |
| PERMISSIONS | Permissions | 权限管理 |

## 状态管理

使用 **Jotai** 进行原子化状态管理。

关键 Atoms：
- `musicSheetsBaseAtom` - 歌单列表状态
- `starredMusicSheetsAtom` - 收藏歌单状态
- `bootstrapAtom` - 应用启动状态

使用方式：
```typescript
import { atom, useAtomValue, getDefaultStore } from 'jotai';

// 读取状态
const sheets = useAtomValue(musicSheetsBaseAtom);

// 更新状态
getDefaultStore().set(musicSheetsBaseAtom, newSheets);
```

## 数据存储

### 存储方案

- **主要存储**: MMKV (高性能键值存储)
- **文件存储**: react-native-fs

### 文件路径

```
basePath/                          # Android: ExternalDirectoryPath
├── plugins/                       # 插件存储
├── log/                           # 日志
├── data/                          # 数据
├── cache/                         # 缓存
│   ├── lrc/                       # 歌词缓存
│   └── download/                  # 下载缓存
├── download/
│   └── music/                     # 下载的音乐
├── local_lrc/                     # 本地歌词
└── mmkv/                          # MMKV存储
```

## 开发命令

```bash
# 安装依赖
npm install

# 启动 Metro
npm run start

# Android 开发
npm run android

# iOS 开发
npm run ios

# 构建 Android Release
npm run build-android

# 代码检查
npm run lint

# 生成资源文件
npm run generate-assets

# 清理构建
npm run clean
```

## 代码规范

### 命名规范

- **组件**: PascalCase (`MusicItem.tsx`)
- **Hook**: camelCase 以 `use` 开头 (`useColors.ts`)
- **工具函数**: camelCase (`mediaUtils.ts`)
- **常量**: UPPER_SNAKE_CASE (`ROUTE_PATH`)
- **类型**: PascalCase，接口以 `I` 开头 (`IMusic.IMusicItem`)

### 文件组织

```
feature/
├── index.tsx              # 主组件导出
├── components/            # 子组件
├── hooks/                 # 相关Hooks
├── store/                 # 状态管理 (atoms)
└── utils/                 # 相关工具
```

### 类型定义

所有类型定义在 `src/types/` 目录下，使用 TypeScript 命名空间组织：

```typescript
declare namespace IMusic {
  interface IMusicItem { ... }
  type IQualityKey = "low" | "standard" | "high" | "super";
}
```

## 常见开发场景

### 添加新页面

1. 在 `src/pages/` 创建页面目录
2. 在 `src/core/router/index.ts` 添加路由路径
3. 在 `src/core/router/routes.tsx` 注册路由

### 添加新组件

1. 在 `src/components/base/` 创建基础组件
2. 或在 `src/components/` 相应分类下创建

### 使用插件能力

```typescript
import PluginManager from '@/core/pluginManager';

// 获取插件
const plugin = PluginManager.getByMedia(musicItem);

// 调用插件方法
const result = await plugin?.methods.search('关键词', 1, 'music');
```

### 播放音乐

```typescript
import TrackPlayer from '@/core/trackPlayer';

// 播放单曲
TrackPlayer.play(musicItem);

// 播放并替换播放列表
TrackPlayer.playWithReplacePlayList(musicItem, musicList);

// 添加到播放列表
TrackPlayer.add(musicItem);
```

---

*最后更新: 2026-04-20*
