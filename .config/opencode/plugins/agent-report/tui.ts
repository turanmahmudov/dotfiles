import { spawn } from 'node:child_process'
import { homedir } from 'node:os'
import { join } from 'node:path'

import type { Plugin } from '@opencode/plugin/tui'

const AGENT = join(homedir(), '.local/bin/agent')

function report(state: string): void {
  spawn(AGENT, ['report', 'opencode', state], { stdio: 'ignore' }).on('error', () => undefined)
}

const plugin: Plugin.Definition = {
  id: 'agent-report',
  setup: context => {
    const isOpen = (sessionID: string) => {
      const route = context.ui.router.current()

      return (route.type === 'session' && route.sessionID === sessionID) || context.ui.tabs.list().some(tab => tab.sessionID === sessionID)
    }

    const stops = [
      context.data.on('session.execution.started', event => {
        if (isOpen(event.data.sessionID)) report('working')
      }),
      ...(['session.execution.succeeded', 'session.execution.failed', 'session.execution.interrupted'] as const).map(type =>
        context.data.on(type, event => {
          if (isOpen(event.data.sessionID)) report('done')
        }),
      ),
      context.data.on('permission.asked', event => {
        if (isOpen(event.data.sessionID)) report('blocked')
      }),
      context.data.on('permission.replied', event => {
        if (isOpen(event.data.sessionID)) report('working')
      }),
    ]

    return () => {
      for (const stop of stops) stop()
      report('gone')
    }
  },
}

export default plugin
