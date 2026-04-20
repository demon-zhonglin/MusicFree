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

  async clear(): Promise<void> {
    if (!this.store) return
    await this.store.clear()
    await this.store.flush()
  }

  async has(key: string): Promise<boolean> {
    if (!this.store) return false
    return await this.store.has(key)
  }
}

export const storageUtil = new StorageUtil()
