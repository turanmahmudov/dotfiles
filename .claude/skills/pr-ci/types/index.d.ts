export type PrCheckBucket = 'pass' | 'fail' | 'pending' | 'skip'

export type PrCheck = { name: string; bucket: PrCheckBucket; link: string }

export type PrSource = 'session' | 'repo'

export type TrackedPr = {
  source: PrSource
  url: string
  repo: string
  number: number
  title: string
  state: string
  checks: PrCheck[]
}

declare module 'claude-code' {
  interface PluginState {
    'pr-ci': { tracked: TrackedPr[] }
  }
}
