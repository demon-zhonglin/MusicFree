import { media } from '@kit.MediaKit'
import { avSession } from '@kit.AVSessionKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { wantAgent, Want } from '@kit.AbilityKit'
import { MusicItem } from '../model/MusicItem'
import { MusicRepeatMode } from '../constants/CommonConst'
import { emitter } from '@kit.BasicServicesKit'
import { Context } from '@kit.AbilityKit'

export enum PlaybackState {
  IDLE = 'idle',
  LOADING = 'loading',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  ERROR = 'error'
}

// 播放器事件常量类 - 使用数字ID
export class PlaybackEvents {
  static readonly STATE_CHANGED: number = 1001
  static readonly TRACK_CHANGED: number = 1002
  static readonly PROGRESS_CHANGED: number = 1003
  static readonly PLAY_END: number = 1004
}

// 事件数据类
export class StateChangedEventData {
  state: PlaybackState = PlaybackState.IDLE
  error: Object | null = null
}

export class TrackChangedEventData {
  music: MusicItem | null = null
}

export class ProgressChangedEventData {
  position: number = 0
  duration: number = 0
}

export class PlayEndEventData {
  placeholder: boolean = true
}

// 事件内部包装类 - 使用 emitter.EventData 兼容类型
class EventInnerData implements emitter.EventData {
  data: Map<string, Object> = new Map()
}

class PlaybackService {
  private avPlayer: media.AVPlayer | null = null
  private session: avSession.AVSession | null = null
  private playList: MusicItem[] = []
  private currentIndex: number = -1
  private repeatMode: MusicRepeatMode = MusicRepeatMode.QUEUE
  private _state: PlaybackState = PlaybackState.IDLE

  get state(): PlaybackState {
    return this._state
  }

  get currentMusic(): MusicItem | null {
    if (this.currentIndex >= 0 && this.currentIndex < this.playList.length) {
      return this.playList[this.currentIndex]
    }
    return null
  }

  get duration(): number {
    if (this.avPlayer !== null) {
      return this.avPlayer.duration
    }
    return 0
  }

  get position(): number {
    if (this.avPlayer !== null) {
      return this.avPlayer.currentTime
    }
    return 0
  }

  get playlist(): MusicItem[] {
    return this.playList
  }

  get currentRepeatMode(): MusicRepeatMode {
    return this.repeatMode
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
    if (this.avPlayer === null) return

    this.avPlayer.on('stateChange', (state: string) => {
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
      this.emitStateChanged(this._state, null)
    })

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.emitProgressChanged(time, this.duration)
    })

    this.avPlayer.on('error', (err: Object) => {
      console.error('AVPlayer error:', err)
      this._state = PlaybackState.ERROR
      this.emitStateChanged(this._state, err)
    })
  }

  private setupSessionCallbacks(): void {
    if (this.session !== null) {
      this.session.on('play', () => this.play())
      this.session.on('pause', () => this.pause())
      this.session.on('playNext', () => this.skipToNext())
      this.session.on('playPrevious', () => this.skipToPrevious())
      this.session.on('seek', (time: number) => this.seekTo(time))
    }
  }

  private async startBackgroundTask(context: Context): Promise<void> {
    try {
      // 创建 wantAgent 用于点击通知时返回应用
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: context.applicationInfo.name,
            abilityName: 'EntryAbility'
          } as Want
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      }
      const agent = await wantAgent.getWantAgent(wantAgentInfo)

      await backgroundTaskManager.startBackgroundRunning(context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, agent)
    } catch (err) {
      console.error('Start background task failed:', err)
    }
  }

  async play(music?: MusicItem): Promise<void> {
    if (music !== undefined) {
      const index = this.findMusicIndex(music)
      if (index >= 0) {
        this.currentIndex = index
      } else {
        this.playList.push(music)
        this.currentIndex = this.playList.length - 1
      }
      this.emitTrackChanged(this.currentMusic)
    }

    const current = this.currentMusic
    if (current === null || current.url === '') return

    try {
      this._state = PlaybackState.LOADING
      this.emitStateChanged(this._state, null)

      if (this.avPlayer !== null) {
        await this.avPlayer.reset()
        this.avPlayer.url = current.url
        await this.avPlayer.prepare()
        await this.avPlayer.play()
      }
      this.updateSessionMetadata()
      this.updateSessionPlaybackState()
    } catch (err) {
      console.error('Play failed:', err)
      this._state = PlaybackState.ERROR
      this.emitStateChanged(this._state, err as Object)
    }
  }

  async pause(): Promise<void> {
    if (this.avPlayer !== null) {
      await this.avPlayer.pause()
    }
    this.updateSessionPlaybackState()
  }

  async resume(): Promise<void> {
    if (this.avPlayer !== null) {
      await this.avPlayer.play()
    }
    this.updateSessionPlaybackState()
  }

  async stop(): Promise<void> {
    if (this.avPlayer !== null) {
      await this.avPlayer.stop()
    }
    this.updateSessionPlaybackState()
  }

  async seekTo(position: number): Promise<void> {
    if (this.avPlayer !== null) {
      this.avPlayer.seek(position)
    }
  }

  async skipToNext(): Promise<void> {
    if (this.playList.length === 0) return

    if (this.repeatMode === MusicRepeatMode.SINGLE) {
      await this.seekTo(0)
      await this.resume()
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
    this.emitTrackChanged(this.currentMusic)
    await this.play()
  }

  async skipToPrevious(): Promise<void> {
    if (this.playList.length === 0) return

    // 如果播放超过3秒，则重新开始当前歌曲
    if (this.position > 3000) {
      await this.seekTo(0)
      return
    }

    let prevIndex = this.currentIndex - 1
    if (prevIndex < 0) {
      prevIndex = this.playList.length - 1
    }
    this.currentIndex = prevIndex
    this.emitTrackChanged(this.currentMusic)
    await this.play()
  }

  setRepeatMode(mode: MusicRepeatMode): void {
    this.repeatMode = mode
  }

  setPlayList(list: MusicItem[], startIndex: number = 0): void {
    this.playList = []
    for (const item of list) {
      this.playList.push(item)
    }
    this.currentIndex = Math.min(startIndex, list.length - 1)
    this.emitTrackChanged(this.currentMusic)
  }

  addToPlayList(music: MusicItem | MusicItem[], insertAfterCurrent: boolean = false): void {
    const items: MusicItem[] = Array.isArray(music) ? music : [music]
    if (insertAfterCurrent && this.currentIndex >= 0) {
      this.playList.splice(this.currentIndex + 1, 0, ...items)
    } else {
      for (const item of items) {
        this.playList.push(item)
      }
    }
  }

  removeFromPlayList(music: MusicItem): void {
    const index = this.findMusicIndex(music)
    if (index >= 0) {
      this.playList.splice(index, 1)
      if (index < this.currentIndex) {
        this.currentIndex--
      } else if (index === this.currentIndex) {
        // 如果删除的是当前播放的歌曲
        if (this.currentIndex >= this.playList.length) {
          this.currentIndex = this.playList.length - 1
        }
        if (this.playList.length > 0) {
          this.play()
        } else {
          this.stop()
        }
      }
    }
  }

  clearPlayList(): void {
    this.playList = []
    this.currentIndex = -1
    this.stop()
  }

  private findMusicIndex(music: MusicItem): number {
    return this.playList.findIndex(
      (m: MusicItem) => m.platform === music.platform && m.id === music.id
    )
  }

  private handlePlayEnd(): void {
    this.emitPlayEnd()
    this.skipToNext()
  }

  private updateSessionMetadata(): void {
    const music = this.currentMusic
    if (music === null || this.session === null) return

    const metadata: avSession.AVMetadata = {
      assetId: music.id,
      title: music.title,
      artist: music.artist,
      album: music.album,
      mediaImage: music.artwork,
      duration: music.duration
    }
    this.session.setAVMetadata(metadata)
  }

  private updateSessionPlaybackState(): void {
    if (this.session === null) return

    let sessionState: avSession.PlaybackState
    switch (this._state) {
      case PlaybackState.PLAYING:
        sessionState = avSession.PlaybackState.PLAYBACK_STATE_PLAY
        break
      case PlaybackState.PAUSED:
        sessionState = avSession.PlaybackState.PLAYBACK_STATE_PAUSE
        break
      case PlaybackState.STOPPED:
        sessionState = avSession.PlaybackState.PLAYBACK_STATE_STOP
        break
      default:
        sessionState = avSession.PlaybackState.PLAYBACK_STATE_INITIAL
    }

    const playbackState: avSession.AVPlaybackState = {
      state: sessionState,
      position: {
        elapsedTime: this.position,
        updateTime: Date.now()
      }
    }
    this.session.setAVPlaybackState(playbackState)
  }

  // 类型安全的事件发送方法
  private emitStateChanged(state: PlaybackState, error: Object | null): void {
    const innerEvent: emitter.InnerEvent = {
      eventId: PlaybackEvents.STATE_CHANGED
    }
    const eventData: emitter.EventData = {
      data: new Map<string, Object>([
        ['state', state as Object],
        ['error', error as Object]
      ])
    }
    emitter.emit(innerEvent, eventData)
  }

  private emitTrackChanged(music: MusicItem | null): void {
    const innerEvent: emitter.InnerEvent = {
      eventId: PlaybackEvents.TRACK_CHANGED
    }
    const eventData: emitter.EventData = {
      data: new Map<string, Object>([
        ['music', music as Object]
      ])
    }
    emitter.emit(innerEvent, eventData)
  }

  private emitProgressChanged(position: number, duration: number): void {
    const innerEvent: emitter.InnerEvent = {
      eventId: PlaybackEvents.PROGRESS_CHANGED
    }
    const eventData: emitter.EventData = {
      data: new Map<string, Object>([
        ['position', position as Object],
        ['duration', duration as Object]
      ])
    }
    emitter.emit(innerEvent, eventData)
  }

  private emitPlayEnd(): void {
    const innerEvent: emitter.InnerEvent = {
      eventId: PlaybackEvents.PLAY_END
    }
    emitter.emit(innerEvent)
  }

  async destroy(): Promise<void> {
    try {
      if (this.avPlayer !== null) {
        await this.avPlayer.release()
      }
      if (this.session !== null) {
        await this.session.destroy()
      }
    } catch (err) {
      console.error('Destroy playback service failed:', err)
    }
    this.avPlayer = null
    this.session = null
    this.playList = []
    this.currentIndex = -1
  }
}

export const playbackService = new PlaybackService()
