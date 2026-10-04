import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import { isReadOnlyTool } from '../core/readonly'

const ASK_PREFIX = /^\s*\?\s*(?=\S)/
const isActive = atom({ plugin: 'ask-only', key: 'isActive' } as const, false)

const CONTEXT = 'This is an ask-only turn. Answer the question only. Do not change files, run commands that change state, or call tools that write. The ask-only mod blocks such tool calls.'

export const register: Register = on => {
  on('prompt.submit', async ($, e, next) => {
    if (!ASK_PREFIX.test(e.text)) return next(e)

    await update($, isActive, () => true)
    $.ui.status('ASK: read-only turn')

    return next({ ...e, text: e.text.replace(ASK_PREFIX, ''), context: [...(e.context ?? []), CONTEXT] })
  })

  on('tool.call', async ($, e, next) => {
    if (!(await read($, isActive))) return next(e)
    if (isReadOnlyTool(e.tool, e as Record<string, unknown>)) return next(e)

    return { deny: `ask-only: ${e.tool} is blocked in an ask-only turn. Answer without changing anything, or tell the user what you would run.` }
  })

  on('turn.complete', async ($, e, next) => {
    if (e.agentId === undefined && (await read($, isActive))) {
      await update($, isActive, () => false)
      $.ui.status(undefined)
    }

    return next(e)
  })
}
