import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

export class RequestOptions {
  method: http.RequestMethod = http.RequestMethod.GET
  headers: Map<string, string> = new Map()
  extraData: string = ''
  connectTimeout: number = 10000
  readTimeout: number = 10000
}

export class ResponseData {
  code: number = 0
  data: string = ''
  message: string = ''
}

class NetworkUtil {
  private httpRequest: http.HttpRequest = http.createHttp()

  async request(url: string, options: RequestOptions | null): Promise<string> {
    const method = options?.method ?? http.RequestMethod.GET
    const connectTimeout = options?.connectTimeout ?? 10000
    const readTimeout = options?.readTimeout ?? 10000

    const defaultOptions: http.HttpRequestOptions = {
      method: method,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: options?.extraData ?? '',
      connectTimeout: connectTimeout,
      readTimeout: readTimeout
    }

    try {
      const response = await this.httpRequest.request(url, defaultOptions)
      if (response.responseCode === http.ResponseCode.OK) {
        return response.result as string
      } else {
        throw new Error(`HTTP Error: ${response.responseCode}`)
      }
    } catch (err) {
      const error = err as BusinessError
      throw new Error(`Network Error: ${error.message}`)
    }
  }

  async get(url: string): Promise<string> {
    const options = new RequestOptions()
    options.method = http.RequestMethod.GET
    return this.request(url, options)
  }

  async post(url: string, data: string): Promise<string> {
    const options = new RequestOptions()
    options.method = http.RequestMethod.POST
    options.extraData = data
    return this.request(url, options)
  }

  destroy(): void {
    this.httpRequest.destroy()
  }
}

export const networkUtil = new NetworkUtil()