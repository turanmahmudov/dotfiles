export type CodeBlock = { language: string; source: string }

declare module 'claude-code' {
  interface PluginState {
    'code-yank': { blocks: CodeBlock[] }
  }
}
