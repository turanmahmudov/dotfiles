export type AsideEntry = { id: number; question: string; answer: string | null; isError: boolean }

declare module 'claude-code' {
  interface PluginState {
    'aside': { entries: AsideEntry[] }
  }
}
