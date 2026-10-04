export type AskOnlyMode = boolean

declare module 'claude-code' {
  interface PluginState {
    'ask-only': { isActive: AskOnlyMode }
  }
}
