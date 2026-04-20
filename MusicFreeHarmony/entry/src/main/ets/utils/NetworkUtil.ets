import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

export interface RequestOptions {
  method?: http.RequestMethod
  headers?: Record<string, string>
  extraData?: string | Object
  connectTimeout?: number
  readTimeout?: number
}

export interface ResponseData<T = unknown> {
  code: number
  data: T
  message?: string
}

class NetworkUtil {
  private httpRequest: http.HttpRequest

  constructor() {
    this.httpRequest = http.createHttp()
  }

  async request<T>(url: string, options?: RequestOptions): Promise<T> {
    const defaultOptions: http.HttpRequestOptions = {
      method: options?.method ?? http.RequestMethod.GET,
      header: {
        'Content-Type': 'application/json',
        ...options?.headers
      },
      extraData: options?.extraData,
      connectTimeout: options?.connectTimeout ?? 10000,
      readTimeout: options?.readTimeout ?? 10000
    }

    try {
      const response = await this.httpRequest.request(url, defaultOptions)
      if (response.responseCode === http.ResponseCode.OK) {
        const result = JSON.parse(response.result as string)
        return result as T
      } else {
        throw new Error(`HTTP Error: ${response.responseCode}`)
      }
    } catch (err) {
      const error = err as BusinessError
      throw new Error(`Network Error: ${error.message}`)
    }
  }

  async get<T>(url: string, options?: Omit<RequestOptions, 'method'>): Promise<T> {
    return this.request<T>(url, { ...options, method: http.RequestMethod.GET })
  }

  async post<T>(url: string, data?: Object, options?: Omit<RequestOptions, 'method' | 'extraData'>): Promise<T> {
    return this.request<T>(url, {
      ...options,
      method: http.RequestMethod.POST,
      extraData: data ? JSON.stringify(data) : undefined
    })
  }

  destroy(): void {
    this.httpRequest.destroy()
  }
}

export const networkUtil = new NetworkUtil()
