import type { SessionMessage } from 'claude-code'

import type { CodeBlock } from '../types'
import { parseCodeBlocks } from '../core/codeblocks'

export function findLastReplyBlocks(messages: readonly SessionMessage[]): CodeBlock[] {
  const blocks: CodeBlock[] = []

  for (let index = messages.length - 1; index >= 0; index--) {
    const message = messages[index]
    if (message === undefined) continue
    if (message.role === 'user' && message.text !== '' && (message.toolResults ?? []).length === 0) {
      if (blocks.length > 0) break
      continue
    }
    if (message.role === 'assistant') blocks.unshift(...parseCodeBlocks(message.text))
  }

  return blocks
}
