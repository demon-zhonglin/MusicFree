import { playbackService, PlaybackState, PlaybackEvents } from '../service/PlaybackService'
import { MusicItem } from '../model/MusicItem'
import { MusicRepeatMode } from '../constants/CommonConst'
import { emitter } from '@kit.BasicServicesKit'
import { FormatUtil } from '../utils/FormatUtil'

@Observed
export class TrackPlayerVM {
  currentMusic: MusicItem | null = null
  playList: MusicItem[] = []
  state: PlaybackState = PlaybackState.IDLE
  position: number = 0
  duration: number = 0
  repeatMode: MusicRepeatMode = MusicRepeatMode.QUEUE
  private listenersSetup: boolean = false

  constructor() {
    this.setupListeners()
  }

  private setupListeners(): void {
    if (this.listenersSetup) return
    
    // 监听状态变化
    const stateEvent: emitter.InnerEvent = {
      eventId: PlaybackEvents.STATE_CHANGED
    }
    emitter.on(stateEvent, (eventData: emitter.EventData) => {
      if (eventData.data !== undefined) {
        const data = eventData.data as Map<string, Object>
        const state = data.get('state') as PlaybackState
        if (state !== undefined) {
          this.state = state
        }
      }
    })

    // 监听曲目变化
    const trackEvent: emitter.InnerEvent = {
      eventId: PlaybackEvents.TRACK_CHANGED
    }
    emitter.on(trackEvent, (eventData: emitter.EventData) => {
      if (eventData.data !== undefined) {
        const data = eventData.data as Map<string, Object>
        this.currentMusic = data.get('music') as MusicItem | null
        this.playList = playbackService.playlist
      }
    })

    // 监听进度变化
    const progressEvent: emitter.InnerEvent = {
      eventId: PlaybackEvents.PROGRESS_CHANGED
    }
    emitter.on(progressEvent, (eventData: emitter.EventData) => {
      if (eventData.data !== undefined) {
        const data = eventData.data as Map<string, Object>
        this.position = data.get('position') as number ?? 0
        this.duration = data.get('duration') as number ?? 0
      }
    })
    
    this.listenersSetup = true
  }

  /**
   * 移除所有事件监听器
   * 在应用退出或不再需要播放器时调用
   */
  teardownListeners(): void {
    if (!this.listenersSetup) return
    
    emitter.off(PlaybackEvents.STATE_CHANGED)
    emitter.off(PlaybackEvents.TRACK_CHANGED)
    emitter.off(PlaybackEvents.PROGRESS_CHANGED)
    
    this.listenersSetup = false
  }

  get isPlaying(): boolean {
    return this.state === PlaybackState.PLAYING
  }

  get isPaused(): boolean {
    return this.state === PlaybackState.PAUSED
  }

  get isLoading(): boolean {
    return this.state === PlaybackState.LOADING
  }

  get isIdle(): boolean {
    return this.state === PlaybackState.IDLE
  }

  get progress(): number {
    return this.duration > 0 ? this.position / this.duration : 0
  }

  get progressPercent(): number {
    return Math.round(this.progress * 100)
  }

  get formattedPosition(): string {
    return FormatUtil.formatTime(this.position)
  }

  get formattedDuration(): string {
    return FormatUtil.formatTime(this.duration)
  }

  async play(music?: MusicItem): Promise<void> {
    await playbackService.play(music)
  }

  async pause(): Promise<void> {
    await playbackService.pause()
  }

  async resume(): Promise<void> {
    await playbackService.resume()
  }

  async togglePlay(): Promise<void> {
    if (this.isPlaying) {
      await this.pause()
    } else {
      await this.resume()
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

  async seekToPercent(percent: number): Promise<void> {
    const newPosition = this.duration * percent
    await this.seekTo(newPosition)
  }

  setRepeatMode(mode: MusicRepeatMode): void {
    this.repeatMode = mode
    playbackService.setRepeatMode(mode)
  }

  cycleRepeatMode(): void {
    switch (this.repeatMode) {
      case MusicRepeatMode.QUEUE:
        this.setRepeatMode(MusicRepeatMode.SINGLE)
        break
      case MusicRepeatMode.SINGLE:
        this.setRepeatMode(MusicRepeatMode.SHUFFLE)
        break
      case MusicRepeatMode.SHUFFLE:
        this.setRepeatMode(MusicRepeatMode.QUEUE)
        break
    }
  }

  setPlayList(list: MusicItem[], startIndex: number = 0): void {
    playbackService.setPlayList(list, startIndex)
    this.playList = list
    if (startIndex >= 0 && startIndex < list.length) {
      this.currentMusic = list[startIndex]
    }
  }

  addToPlayList(music: MusicItem | MusicItem[], insertAfterCurrent: boolean = false): void {
    playbackService.addToPlayList(music, insertAfterCurrent)
    this.playList = playbackService.playlist
  }

  removeFromPlayList(music: MusicItem): void {
    playbackService.removeFromPlayList(music)
    this.playList = playbackService.playlist
  }

  clearPlayList(): void {
    playbackService.clearPlayList()
    this.playList = []
    this.currentMusic = null
  }

  // 获取播放模式图标名称
  getRepeatModeIcon(): string {
    switch (this.repeatMode) {
      case MusicRepeatMode.SINGLE:
        return 'repeat_one'
      case MusicRepeatMode.SHUFFLE:
        return 'shuffle'
      default:
        return 'repeat'
    }
  }

  // 获取播放模式描述
  getRepeatModeLabel(): string {
    switch (this.repeatMode) {
      case MusicRepeatMode.SINGLE:
        return '单曲循环'
      case MusicRepeatMode.SHUFFLE:
        return '随机播放'
      default:
        return '列表循环'
    }
  }
}

// 全局单例
let trackPlayerVMInstance: TrackPlayerVM | null = null

export function getTrackPlayerVM(): TrackPlayerVM {
  if (trackPlayerVMInstance === null) {
    trackPlayerVMInstance = new TrackPlayerVM()
  }
  return trackPlayerVMInstance
}