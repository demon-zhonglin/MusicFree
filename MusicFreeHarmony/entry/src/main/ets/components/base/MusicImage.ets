/**
 * 图片加载状态
 */
enum ImageLoadState {
  IDLE,
  LOADING,
  SUCCESS,
  ERROR
}

/**
 * 图片尺寸预设
 * 用于不同场景的图片尺寸优化
 */
export enum ImageSizePreset {
  THUMBNAIL = 48,      // 列表缩略图
  SMALL = 64,          // 小图
  MEDIUM = 120,        // 中等尺寸
  LARGE = 200,         // 大图
  COVER = 300          // 封面图
}

/**
 * 音乐图片组件
 * 优化特性：
 * - 图片缓存
 * - 加载状态显示
 * - 错误重试
 * - 尺寸预设
 */
@Component
export struct MusicImage {
  @Prop src: string = ''
  @Prop imageSize: number = ImageSizePreset.THUMBNAIL
  @Prop radius: number = 8
  @Prop showLoading: boolean = false  // 是否显示加载状态
  @Prop retryCount: number = 2        // 失败重试次数
  
  @State private loadState: ImageLoadState = ImageLoadState.IDLE
  @State private currentRetry: number = 0
  @State private currentSrc: string = ''

  aboutToAppear(): void {
    this.currentSrc = this.src
  }

  aboutToUpdate(): void {
    // 当 src 变化时重置状态
    if (this.src !== this.currentSrc) {
      this.currentSrc = this.src
      this.loadState = ImageLoadState.IDLE
      this.currentRetry = 0
    }
  }

  build() {
    Stack() {
      if (this.currentSrc && this.currentSrc.length > 0) {
        Image(this.currentSrc)
          .width(this.imageSize)
          .height(this.imageSize)
          .borderRadius(this.radius)
          .objectFit(ImageFit.Cover)
          .alt($r('app.media.album_default'))
          .interpolation(ImageInterpolation.Medium)  // 图片插值质量
          .onComplete(() => {
            this.loadState = ImageLoadState.SUCCESS
          })
          .onError(() => {
            this.loadState = ImageLoadState.ERROR
            // 自动重试
            if (this.currentRetry < this.retryCount) {
              this.currentRetry++
              // 触发重新加载
              setTimeout(() => {
                this.currentSrc = this.src + (this.src.includes('?') ? '&' : '?') + `retry=${this.currentRetry}`
              }, 500)
            }
          })
        
        // 加载状态指示器
        if (this.showLoading && this.loadState === ImageLoadState.LOADING) {
          LoadingProgress()
            .width(this.imageSize / 3)
            .height(this.imageSize / 3)
            .color(Color.White)
        }
      } else {
        // 默认图片
        Image($r('app.media.album_default'))
          .width(this.imageSize)
          .height(this.imageSize)
          .borderRadius(this.radius)
          .objectFit(ImageFit.Cover)
      }
    }
    .width(this.imageSize)
    .height(this.imageSize)
  }

  /**
   * 重新加载图片
   */
  reload(): void {
    if (this.currentRetry < this.retryCount) {
      this.currentRetry++
      this.currentSrc = this.src + (this.src.includes('?') ? '&' : '?') + `reload=${Date.now()}`
    }
  }
}

/**
 * 圆形音乐图片组件
 */
@Component
export struct MusicImageCircle {
  @Prop src: string = ''
  @Prop imageSize: number = ImageSizePreset.THUMBNAIL
  @Prop showLoading: boolean = false

  build() {
    MusicImage({
      src: this.src,
      imageSize: this.imageSize,
      radius: this.imageSize / 2,
      showLoading: this.showLoading
    })
  }
}

/**
 * 大尺寸音乐图片组件（用于封面等）
 */
@Component
export struct MusicImageCover {
  @Prop src: string = ''
  @Prop imageSize: number = ImageSizePreset.COVER
  @Prop showLoading: boolean = true

  build() {
    MusicImage({
      src: this.src,
      imageSize: this.imageSize,
      radius: 12,
      showLoading: this.showLoading
    })
  }
}

/**
 * 列表缩略图组件（优化尺寸）
 */
@Component
export struct MusicImageThumbnail {
  @Prop src: string = ''

  build() {
    MusicImage({
      src: this.src,
      imageSize: ImageSizePreset.THUMBNAIL,
      radius: 8,
      showLoading: false
    })
  }
}
