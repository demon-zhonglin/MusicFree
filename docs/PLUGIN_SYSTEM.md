# MusicFree 插件系统详解

> 本文档详细介绍 MusicFree 的插件系统架构、核心组件及开发指南。

## 目录

- [整体架构](#整体架构)
- [核心组件](#核心组件)
  - [PluginManager](#1-pluginmanager-插件管理器)
  - [Plugin 类](#2-plugin-类)
  - [PluginMethodsWrapper](#3-pluginmethodswrapper-方法包装器)
  - [PluginMeta](#4-pluginmeta-元数据存储)
- [插件接口定义](#插件接口定义)
- [插件生命周期](#插件生命周期)
- [播放源解析流程](#播放源解析流程)
- [用户界面](#用户界面)
- [内置本地文件插件](#内置本地文件插件)
- [插件开发指南](#插件开发指南)
- [设计亮点](#设计亮点)

---

## 整体架构

MusicFree 采用**高度可扩展的插件化架构**，将播放器核心功能与音源完全分离，允许用户安装第三方插件来接入不同的音乐源。

```
┌─────────────────────────────────────────────────────────────┐
│                      应用层 (UI/Pages)                       │
├─────────────────────────────────────────────────────────────┤
│                   PluginManager (插件管理器)                  │
├───────────────┬─────────────────────┬───────────────────────┤
│   Plugin 类   │   PluginMeta 类     │  PluginMethodsWrapper │
│   (插件实例)   │   (插件元数据存储)   │   (方法包装器)         │
├───────────────┴─────────────────────┴───────────────────────┤
│              IPluginDefine (插件接口定义)                     │
└─────────────────────────────────────────────────────────────┘
```

**核心文件位置**:
```
src/core/pluginManager/
├── index.ts      # PluginManager 主类
├── plugin.ts     # Plugin 类和 PluginMethodsWrapper
└── meta.ts       # PluginMeta 元数据管理
```

---

## 核心组件

### 1. PluginManager (插件管理器)

**文件**: `src/core/pluginManager/index.ts`

**职责**: 插件的生命周期管理、安装/卸载/更新、查询等。

#### 核心功能一览

| 功能分类 | 方法 | 描述 |
|---------|------|------|
| **初始化** | `setup()` | 从文件系统加载所有 `.js` 插件文件 |
| **安装** | `installPluginFromLocalFile()` | 从本地文件安装插件 |
| | `installPluginFromUrl()` | 从远程 URL 安装插件 |
| **卸载** | `uninstallPlugin(hash)` | 通过哈希值卸载插件 |
| | `uninstallAllPlugins()` | 卸载所有插件 |
| **更新** | `updatePlugin(plugin)` | 从源 URL 更新插件 |
| **查询** | `getByMedia(mediaItem)` | 根据媒体项获取对应插件 |
| | `getByName(name)` | 根据名称获取插件 |
| | `getByHash(hash)` | 根据哈希值获取插件 |
| | `getEnabledPlugins()` | 获取所有已启用的插件 |
| | `getSortedPlugins()` | 获取按顺序排序的插件 |
| | `getSearchablePlugins(type?)` | 获取支持搜索的插件 |
| | `getPluginsWithAbility(ability)` | 获取支持特定能力的插件 |
| **状态控制** | `setPluginEnabled(plugin, enabled)` | 启用/禁用插件 |
| | `isPluginEnabled(plugin)` | 检查插件是否启用 |
| **排序** | `setPluginOrder(sortedPlugins)` | 设置插件排序 |
| **替代插件** | `setAlternativePluginName()` | 设置备用解析源 |
| | `getAlternativePlugin()` | 获取备用插件 |
| **用户变量** | `setUserVariables()` / `getUserVariables()` | 管理用户自定义变量 |

#### 状态管理

使用 **Jotai** 原子化状态管理插件列表：

```typescript
const pluginsAtom = atom<Plugin[]>([]);

// React Hooks
export const usePlugins = () => useAtomValue(pluginsAtom);
export function useSortedPlugins() { ... }
export function usePluginEnabled(plugin: Plugin) { ... }
```

#### 事件系统

使用 `EventEmitter` 广播插件状态变更：

```typescript
const ee = new EventEmitter<{
    "order-updated": () => void;
    "enabled-updated": (pluginName: string, enabled: boolean) => void;
}>();
```

---

### 2. Plugin 类

**文件**: `src/core/pluginManager/plugin.ts`

**职责**: 单个插件的实例化、挂载和方法执行。

#### 插件状态枚举

```typescript
enum PluginState {
    Initializing,  // 初始化中（懒加载模式）
    Loading,       // 加载中
    Mounted,       // 已挂载（可用）
    Error          // 出错
}

enum PluginErrorReason {
    VersionNotMatch,  // 版本不兼容
    CannotParse,      // 无法解析
}
```

#### 核心属性

```typescript
class Plugin {
    name: string;                    // 插件名（平台标识）
    hash: string;                    // 唯一标识（SHA256）
    state: PluginState;              // 当前状态
    errorReason?: PluginErrorReason; // 错误原因
    instance: IPluginDefine;         // 插件实例对象
    path: string;                    // 文件路径
    methods: IPluginInstanceMethods; // 方法包装器
    supportedMethods: Set<string>;   // 支持的方法集合
}
```

#### 沙箱执行环境

插件代码在受限的沙箱环境中执行，只能访问预定义的包和环境变量：

**可用的第三方包**:
```typescript
const packages = {
    cheerio,           // HTML/XML 解析
    "crypto-js": CryptoJs,  // 加密算法
    axios,             // HTTP 请求
    dayjs,             // 日期处理
    "big-integer": bigInt,  // 大整数
    qs,                // 查询字符串解析
    he,                // HTML 实体编解码
    webdav,            // WebDAV 客户端
};
```

**环境变量**:
```typescript
const env = {
    getUserVariables: () => { ... },  // 获取用户配置的变量
    appVersion,        // App 版本号
    os: "android",     // 操作系统
    lang: "zh-CN",     // 语言
};
```

**代码注入方式**:
```typescript
Function(`
    'use strict';
    return function(require, __musicfree_require, module, exports, console, env, URL, process) {
        ${funcCode}
    }
`)()(
    _require,      // 受限的 require 函数
    _require,
    _module,       // CommonJS module 对象
    _module.exports,
    _console,      // 包装的 console
    env,           // 环境变量
    URL,           // URL 构造器
    _process       // 进程信息
);
```

#### 懒加载机制

支持延迟加载插件代码以优化启动性能：

```typescript
interface ILazyProps {
    name: string;
    hash: string;
    path: string;
    supportedMethods?: string[];
    loadFuncCode?: () => Promise<string>;
    instance?: IPluginDefine;
}

// 懒加载插件在首次调用方法时才真正挂载
async ensureMounted() {
    if (this.state === PluginState.Initializing && this.lazyProps) {
        const funcCode = await this.lazyProps.loadFuncCode();
        this.mountPlugin(funcCode, this.lazyProps.path);
    }
}
```

---

### 3. PluginMethodsWrapper (方法包装器)

**职责**: 包装插件方法，确保调用前插件已挂载，统一处理返回数据格式。

#### 包装的方法列表

| 方法 | 功能 | 返回类型 |
|------|------|----------|
| `search(query, page, type)` | 搜索音乐/专辑/歌手等 | `ISearchResult<T>` |
| `getMediaSource(musicItem, quality)` | 获取播放源 URL | `IMediaSourceResult` |
| `getMusicInfo(musicItem)` | 获取音乐详情 | `Partial<IMusicItem>` |
| `getLyric(musicItem)` | 获取歌词 | `ILyricSource` |
| `getAlbumInfo(albumItem, page)` | 获取专辑信息 | `IAlbumInfoResult` |
| `getMusicSheetInfo(sheetItem, page)` | 获取歌单信息 | `ISheetInfoResult` |
| `getArtistWorks(artistItem, page, type)` | 获取艺术家作品 | `ISearchResult<T>` |
| `importMusicSheet(urlLike)` | 导入歌单 | `IMusicItem[]` |
| `importMusicItem(urlLike)` | 导入单曲 | `IMusicItem` |
| `getTopLists()` | 获取排行榜 | `IMusicSheetGroupItem[]` |
| `getTopListDetail(topListItem, page)` | 获取榜单详情 | `ITopListInfoResult` |
| `getRecommendSheetTags()` | 获取推荐歌单标签 | `IGetRecommendSheetTagsResult` |
| `getRecommendSheetsByTag(tag, page)` | 获取标签下的歌单 | `PaginationResponse` |
| `getMusicComments(musicItem, page)` | 获取评论 | `PaginationResponse` |

#### 数据标准化

所有方法返回的媒体数据都会调用 `resetMediaItem()` 进行标准化：

```typescript
result.data.forEach(_ => {
    resetMediaItem(_, this.plugin.name);  // 添加 platform 标识
});
```

---

### 4. PluginMeta (元数据存储)

**文件**: `src/core/pluginManager/meta.ts`

**职责**: 持久化插件元数据，使用 MMKV 存储。

#### 存储结构

```typescript
interface IPluginMetaStorage {
    $version: number;                    // 存储格式版本号
    order: Record<string, number>;       // 插件排序映射
    disabledPlugins: Array<string>;      // 禁用的插件名列表
    [key: `${string}.alternativePlugin`]: string | null;  // 替代插件设置
    [key: `${string}.userVariables`]: Record<string, string>; // 用户变量
}
```

#### 主要方法

```typescript
class PluginMeta {
    // 排序管理
    getPluginOrder(): Record<string, number>
    setPluginOrder(orderMap: Record<string, number>): void
    
    // 启用状态
    isPluginEnabled(pluginPlatform: string): boolean
    setPluginEnabled(pluginPlatform: string, enabled: boolean): void
    
    // 用户变量
    getUserVariables(pluginPlatform: string): Record<string, string>
    setUserVariables(pluginPlatform: string, userVariables: Record<string, string>): void
    
    // 替代插件
    getAlternativePlugin(pluginPlatform: string): string | null
    setAlternativePlugin(pluginPlatform: string, alternativePluginPlatform: string): void
    
    // 数据迁移
    migratePluginMeta(): Promise<void>  // 从 AsyncStorage 迁移到 MMKV
}
```

---

## 插件接口定义

**文件**: `src/types/plugin.d.ts`

每个插件必须实现 `IPluginDefine` 接口：

```typescript
declare namespace IPlugin {
    interface IPluginDefine {
        // ============ 必填字段 ============
        /** 平台名称（唯一标识） */
        platform: string;
        
        // ============ 可选配置 ============
        /** 兼容的 App 版本号（semver 格式） */
        appVersion?: string;
        /** 插件版本 */
        version?: string;
        /** 远程更新 URL */
        srcUrl?: string;
        /** 主键字段，会被存储到 mediameta 中 */
        primaryKey?: string[];
        /** 默认搜索类型 */
        defaultSearchType?: ICommon.SupportMediaType;
        /** 支持的搜索类型 */
        supportedSearchType?: ICommon.SupportMediaType[];
        /** 缓存控制策略 */
        cacheControl?: "cache" | "no-cache" | "no-store";
        /** 插件作者 */
        author?: string;
        /** 插件描述（支持 Markdown） */
        description?: string;
        /** 用户自定义输入变量 */
        userVariables?: IUserVariable[];
        /** 提示文本 */
        hints?: Record<string, string[]>;
        
        // ============ 可选方法 ============
        /** 搜索 */
        search?: ISearchFunc;
        /** 获取播放源 */
        getMediaSource?: (musicItem: IMusicItemBase, quality: IQualityKey) 
            => Promise<IMediaSourceResult | null>;
        /** 获取音乐详情 */
        getMusicInfo?: (musicBase: IMediaBase) 
            => Promise<Partial<IMusicItem> | null>;
        /** 获取歌词 */
        getLyric?: (musicItem: IMusicItemBase) 
            => Promise<ILyricSource | null>;
        /** 获取专辑信息 */
        getAlbumInfo?: (albumItem: IAlbumItemBase, page: number) 
            => Promise<IAlbumInfoResult | null>;
        /** 获取歌单信息 */
        getMusicSheetInfo?: (sheetItem: IMusicSheetItem, page: number) 
            => Promise<ISheetInfoResult | null>;
        /** 获取艺术家作品 */
        getArtistWorks?: IGetArtistWorksFunc;
        /** 导入歌单 */
        importMusicSheet?: (urlLike: string) 
            => Promise<IMusicItem[] | null>;
        /** 导入单曲 */
        importMusicItem?: (urlLike: string) 
            => Promise<IMusicItem | null>;
        /** 获取排行榜 */
        getTopLists?: () => Promise<IMusicSheetGroupItem[]>;
        /** 获取榜单详情 */
        getTopListDetail?: (topListItem: IMusicSheetItemBase, page: number) 
            => Promise<ITopListInfoResult>;
        /** 获取推荐歌单标签 */
        getRecommendSheetTags?: () => Promise<IGetRecommendSheetTagsResult>;
        /** 获取标签下的歌单列表 */
        getRecommendSheetsByTag?: (tag: IUnique, page?: number) 
            => Promise<PaginationResponse<IMusicSheetItemBase>>;
        /** 获取评论 */
        getMusicComments?: (musicItem: IMusicItem, page?: number) 
            => Promise<PaginationResponse<IComment>>;
    }
    
    /** 用户变量定义 */
    interface IUserVariable {
        key: string;     // 变量键名
        name?: string;   // 显示名称
        hint?: string;   // 提示文案
    }
    
    /** 播放源结果 */
    interface IMediaSourceResult {
        url?: string;
        headers?: Record<string, string>;
        userAgent?: string;
        quality?: IQualityKey;
    }
    
    /** 搜索结果 */
    interface ISearchResult<T> {
        isEnd?: boolean;
        data: SupportMediaItemBase[T][];
    }
}
```

---

## 插件生命周期

### 安装流程

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  本地文件 / URL  │───▶│   下载/读取代码   │───▶│   创建 Plugin    │
└─────────────────┘    └─────────────────┘    └───────┬─────────┘
                                                      │
                       ┌─────────────────┐            │
                       │   版本检查       │◀───────────┘
                       │   (可跳过)       │
                       └───────┬─────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│  已安装相同版本 │      │  已有旧版本     │      │   全新安装     │
│  (静默忽略)    │      │  (替换旧版本)   │      │  (复制到目录)  │
└───────────────┘      └───────────────┘      └───────────────┘
```

### 加载流程

```
应用启动
    │
    ▼
PluginManager.setup()
    │
    ▼
读取 plugins/ 目录下所有 .js 文件
    │
    ▼
┌─────────────────────────────────────┐
│  是否启用懒加载 (basic.lazyLoadPlugin) │
└───────────────────┬─────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
   [启用懒加载]            [立即加载]
        │                       │
        ▼                       ▼
从缓存读取元数据          读取并执行插件代码
创建 Initializing 状态     创建 Mounted 状态
        │                       │
        └───────────┬───────────┘
                    ▼
            首次调用方法时
                    │
                    ▼ (懒加载插件)
            ensureMounted()
                    │
                    ▼
            读取并执行插件代码
            状态变为 Mounted
```

---

## 播放源解析流程

```typescript
async getMediaSource(musicItem, quality) {
    // 1️⃣ 检查本地文件
    const localPath = getLocalPath(musicItem);
    if (localPath && await exists(localPath)) {
        return { url: addFileScheme(localPath) };
    }
    
    // 2️⃣ 检查缓存（根据 cacheControl 策略）
    const mediaCache = MediaCache.getMediaCache(musicItem);
    if (mediaCache?.source?.[quality]?.url) {
        const cacheControl = this.plugin.instance.cacheControl ?? "no-cache";
        if (cacheControl === "cache" || 
            (cacheControl === "no-cache" && Network.isOffline)) {
            return cachedSource;
        }
    }
    
    // 3️⃣ 检查替代插件
    const alternativePlugin = Plugin.pluginManager?.getAlternativePlugin(this.plugin);
    const parserPlugin = alternativePlugin?.instance?.getMediaSource 
        ? alternativePlugin 
        : this.plugin;
    
    // 4️⃣ 调用插件解析
    if (!parserPlugin.instance.getMediaSource) {
        // 无解析方法，使用原始 URL
        return { url: musicItem.url };
    }
    
    const result = await parserPlugin.instance.getMediaSource(musicItem, quality);
    
    // 5️⃣ 更新缓存（非 no-store 模式）
    if (cacheControl !== "no-store") {
        MediaCache.setMediaCache({ ...musicItem, source: { [quality]: result } });
    }
    
    return result;
}
```

---

## 用户界面

### 插件管理页面结构

**文件**: `src/pages/setting/settingTypes/pluginSetting/`

```
pluginSetting/
├── index.tsx              # 导航配置
├── components/
│   └── pluginItem.tsx     # 单个插件卡片组件
└── views/
    ├── pluginList.tsx     # 插件列表页
    ├── pluginSort.tsx     # 插件排序页
    └── pluginSubscribe.tsx # 订阅管理页
```

### 路由配置

| 路径 | 组件 | 功能 |
|------|------|------|
| `/pluginsetting/list` | PluginList | 显示所有已安装插件 |
| `/pluginsetting/sort` | PluginSort | 调整插件优先级顺序 |
| `/pluginsetting/subscribe` | PluginSubscribe | 管理插件订阅源 |

### PluginItem 功能

每个插件卡片提供以下操作：

| 操作 | 条件 | 描述 |
|------|------|------|
| 启用/禁用 | 始终可用 | 切换插件状态 |
| 更新插件 | 有 `srcUrl` | 从远程更新 |
| 分享插件 | 有 `srcUrl` | 复制 URL 到剪贴板 |
| 卸载插件 | 始终可用 | 删除插件 |
| 设置替代插件 | 始终可用 | 选择备用解析源 |
| 导入音乐 | 有 `importMusicItem` 方法 | 从 URL 导入单曲 |
| 导入歌单 | 有 `importMusicSheet` 方法 | 从 URL 导入歌单 |
| 用户变量 | 有 `userVariables` 定义 | 配置自定义变量 |
| 查看描述 | 有 `description` | 显示 Markdown 描述 |

---

## 内置本地文件插件

系统内置一个本地文件插件，处理本地音乐文件的播放：

**文件**: `src/core/pluginManager/plugin.ts` (底部)

```typescript
const localFilePluginDefine: IPluginDefine = {
    platform: "本地",  // localPluginPlatform
    
    async getMusicInfo(musicBase) {
        const localPath = getLocalPath(musicBase);
        if (localPath) {
            const coverImg = await Mp3Util.getMediaCoverImg(localPath);
            return { artwork: coverImg };
        }
        return null;
    },
    
    async getLyric(musicBase) {
        const localPath = getLocalPath(musicBase);
        if (localPath) {
            // 1. 尝试读取内嵌歌词
            let rawLrc = await Mp3Util.getLyric(localPath);
            if (!rawLrc) {
                // 2. 尝试读取同名 .lrc 文件
                const lrcPath = localPath.replace(/\.[^.]+$/, '.lrc');
                if (await exists(lrcPath)) {
                    rawLrc = await readFile(lrcPath, 'utf8');
                }
            }
            return rawLrc ? { rawLrc } : null;
        }
        return null;
    },
    
    async importMusicItem(urlLike) {
        // 解析本地文件元数据
        const meta = await Mp3Util.getBasicMeta(urlLike);
        return {
            id: md5(fileStat.originalFilepath),
            platform: "本地",
            title: meta?.title ?? getFileName(urlLike),
            artist: meta?.artist ?? "未知歌手",
            duration: parseInt(meta?.duration ?? "0") / 1000,
            album: meta?.album ?? "未知专辑",
            url: urlLike,
        };
    },
    
    async getMediaSource(musicItem, quality) {
        if (quality === "standard") {
            return { url: addFileScheme(musicItem.url) };
        }
        return null;
    },
};

export const localFilePlugin = new Plugin(
    () => localFilePluginDefine,
    "internal-plugin://local-file-plugin"
);
```

---

## 插件开发指南

### 基础插件模板

```javascript
module.exports = {
    // ======== 基本信息 ========
    platform: "我的音乐源",
    version: "1.0.0",
    srcUrl: "https://example.com/plugin.js",
    author: "开发者名称",
    description: "插件描述，支持 **Markdown** 格式",
    
    // ======== 搜索配置 ========
    defaultSearchType: "music",
    supportedSearchType: ["music", "album", "artist", "sheet"],
    cacheControl: "no-cache",
    
    // ======== 用户变量 ========
    userVariables: [
        {
            key: "cookie",
            name: "登录 Cookie",
            hint: "请在浏览器登录后获取 Cookie"
        }
    ],
    
    // ======== 搜索方法 ========
    async search(query, page, type) {
        const axios = require('axios');
        const response = await axios.get('https://api.example.com/search', {
            params: { keyword: query, page, type }
        });
        
        return {
            isEnd: response.data.hasMore === false,
            data: response.data.list.map(item => ({
                id: item.id,
                title: item.name,
                artist: item.singer,
                album: item.albumName,
                artwork: item.cover,
                duration: item.duration,
            }))
        };
    },
    
    // ======== 获取播放源 ========
    async getMediaSource(musicItem, quality) {
        const axios = require('axios');
        const response = await axios.get('https://api.example.com/url', {
            params: { id: musicItem.id, quality }
        });
        
        return {
            url: response.data.url,
            headers: {
                'Referer': 'https://example.com'
            }
        };
    },
    
    // ======== 获取歌词 ========
    async getLyric(musicItem) {
        const axios = require('axios');
        const response = await axios.get('https://api.example.com/lyric', {
            params: { id: musicItem.id }
        });
        
        return {
            rawLrc: response.data.lrc,
            translation: response.data.tlyric
        };
    },
    
    // ======== 获取专辑信息 ========
    async getAlbumInfo(albumItem, page) {
        const axios = require('axios');
        const response = await axios.get('https://api.example.com/album', {
            params: { id: albumItem.id, page }
        });
        
        return {
            albumItem: {
                ...albumItem,
                description: response.data.description,
                artwork: response.data.cover,
            },
            musicList: response.data.songs,
            isEnd: response.data.hasMore === false
        };
    },
    
    // ======== 导入歌单 ========
    async importMusicSheet(urlLike) {
        // 解析 URL 中的歌单 ID
        const match = urlLike.match(/playlist\/(\d+)/);
        if (!match) return null;
        
        const axios = require('axios');
        const response = await axios.get('https://api.example.com/playlist', {
            params: { id: match[1] }
        });
        
        return response.data.songs;
    },
    
    // ======== 获取排行榜 ========
    async getTopLists() {
        const axios = require('axios');
        const response = await axios.get('https://api.example.com/toplist');
        
        return response.data.map(group => ({
            title: group.name,
            data: group.list.map(item => ({
                id: item.id,
                title: item.name,
                artwork: item.cover,
            }))
        }));
    },
};
```

### 使用用户变量

```javascript
module.exports = {
    platform: "需要登录的音乐源",
    
    userVariables: [
        { key: "cookie", name: "Cookie", hint: "登录后的 Cookie" },
        { key: "uid", name: "用户ID" }
    ],
    
    async search(query, page, type) {
        // 通过 env 获取用户变量
        const { cookie, uid } = env.userVariables;
        
        const axios = require('axios');
        const response = await axios.get('https://api.example.com/search', {
            params: { keyword: query },
            headers: { 'Cookie': cookie }
        });
        
        return { data: response.data.list };
    }
};
```

### 调试技巧

```javascript
module.exports = {
    platform: "测试插件",
    
    async search(query, page, type) {
        // 使用 console 输出调试信息
        // 日志会显示在开发者工具中
        console.log('搜索参数:', { query, page, type });
        console.log('环境变量:', env);
        console.log('用户变量:', env.userVariables);
        
        try {
            const result = await fetchData();
            console.log('请求结果:', result);
            return result;
        } catch (error) {
            console.error('请求失败:', error.message);
            throw error;
        }
    }
};
```

---

## 设计亮点

| 特性 | 实现方式 | 优势 |
|------|----------|------|
| **安全隔离** | `Function()` 沙箱 + 受限包列表 | 防止恶意代码访问敏感 API |
| **懒加载** | `ILazyProps` + 缓存元数据 | 优化应用启动时间 |
| **版本校验** | `compare-versions` 库 | 确保插件与 App 版本兼容 |
| **缓存机制** | 三级策略：cache/no-cache/no-store | 灵活控制缓存行为 |
| **替代插件** | `alternativePlugin` 映射 | 允许设置备用解析源 |
| **用户变量** | `userVariables` + MMKV 持久化 | 支持用户自定义配置 |
| **热更新** | `srcUrl` + `updatePlugin()` | 无需重装即可更新 |
| **订阅模式** | 批量 URL 安装 | 一键安装多个插件 |
| **状态管理** | Jotai + EventEmitter | 响应式 UI 更新 |
| **数据标准化** | `resetMediaItem()` | 统一媒体数据格式 |

---

*最后更新: 2026-04-21*
