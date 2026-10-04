import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, RenderSurface } from 'claude-code'

import type { CodeBlock } from '../types'
import { describeBlock } from '../core/codeblocks'
import { findLastReplyBlocks } from './blocks'

const PANE = 'code-yank'
const HOTKEYS = '123456789abcdefghijklmnopqrstuvwxyz'
const blocks = atom({ plugin: 'code-yank', key: 'blocks' } as const, [])

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'yank',
      description: 'Copy a code block of the last reply to the clipboard',
      argumentHint: '[number]',
    })

    return next(e)
  })

  on('command.run', { command: 'yank' }, async ($, e) => {
    const messages = await $.session.messages({})
    if (!Array.isArray(messages)) return { text: `Cannot read the conversation: ${messages.deny}` }

    const found = findLastReplyBlocks(messages)
    if (found.length === 0) return { text: 'The last reply has no code blocks.' }

    const chosen = e.args.trim() === '' ? undefined : found[Number.parseInt(e.args, 10) - 1]
    if (e.args.trim() !== '' && chosen === undefined) return { text: `There is no code block ${e.args.trim()}. The last reply has ${found.length}.` }
    if (chosen !== undefined) return { text: await copyBlock($, chosen) }
    if (found.length === 1) return { text: await copyBlock($, found[0] as CodeBlock) }

    await update($, blocks, () => found)

    await $.ui.open({ id: PANE, title: 'Yank', focus: true, closeOnEscape: true, rows: Math.min(found.length, HOTKEYS.length) + 1 })

    return { text: `${found.length} code blocks. Press a key to copy one.` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const list = (await read($, blocks)).slice(0, HOTKEYS.length)
    const width = Math.max(20, (e.props.bodyColumns ?? 80) - 6)

    return (
      <Box flexDirection="column">
        {list.map((block, index) => (
          <Box key={`row-${index}`}>
            <Button
              key={`copy-${index}`}
              plain
              hotkey={HOTKEYS[index]}
              label={describeBlock(block).slice(0, width)}
              autoFocus={index === 0 ? true : undefined}
              onPress={async () => {
                $.ui.toast(await copyBlock($, block, e.surface))
                await $.ui.close({ id: PANE })
              }}
            />
          </Box>
        ))}
        {list.length === 0 && <Text dimColor>No code blocks.</Text>}
      </Box>
    )
  })
}

async function copyBlock($: EngineInterface, block: CodeBlock, surface?: RenderSurface): Promise<string> {
  const copied = await $.ui.copy({ text: block.source, surface })

  return copied.isCopied ? `Copied: ${describeBlock(block)}` : `Copy failed: ${copied.reason}`
}
