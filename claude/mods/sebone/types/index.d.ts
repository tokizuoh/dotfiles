export type Quote = { text: string; source?: string }

declare module 'claude-code' {
  interface PluginState {
    sebone: { current: Quote | null }
  }
}
