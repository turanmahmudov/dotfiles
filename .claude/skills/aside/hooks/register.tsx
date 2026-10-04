import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { AsideEntry } from '../types'
import { ASIDE_PROMPT, describeFailure } from '../core/prompt'

const PANE = 'aside'
const KEPT_ENTRIES = 20
const entries = atom({ plugin: 'aside', key: 'entries' } as const, [])


export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'aside',
      description: 'Ask a side question about this session without adding it to the conversation',
      argumentHint: '[question]',
      immediate: true,
    })

    return next(e)
  })

  on('command.run', { command: 'aside' }, async ($, e) => {
    await $.ui.open({ id: PANE, title: 'Aside', focus: true, closeOnEscape: true })
    if (e.args.trim() !== '') void askAside($, e.args.trim())

    return { text: 'Aside opened.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Markdown, Text } = $.ui.resolve(e)
    const Input = e.surface === 'mobile' ? undefined : $.ui.resolve(e).Input
    const list = await read($, entries)
    const room = Math.max(1, Math.floor(((e.viewport?.rows ?? 30) - 4) / 6))

    return (
      <Box flexDirection="column">
        {list.length === 0 && <Text dimColor>Ask about the session. The main conversation does not see it.</Text>}
        {list.slice(-room).map(entry => (
          <Box key={`entry-${entry.id}`} flexDirection="column" marginBottom={1}>
            <Text bold>{'> '}{entry.question}</Text>
            {entry.answer === null ? (
              <Text dimColor>Thinking...</Text>
            ) : entry.isError ? (
              <Text color="red">{entry.answer}</Text>
            ) : (
              <Markdown key={`answer-${entry.id}`} text={entry.answer} />
            )}
          </Box>
        ))}
        {Input !== undefined && (
          <Input key="question" placeholder="Ask about the session" submitLabel="ask" autoFocus onSubmit={(value: string) => void askAside($, value)} />
        )}
      </Box>
    )
  })
}

async function askAside($: EngineInterface, question: string): Promise<void> {
  const text = question.trim()
  if (text === '') return

  const id = Math.max(0, ...(await read($, entries)).map(entry => entry.id)) + 1
  await update($, entries, list => [...list, { id, question: text, answer: null, isError: false }].slice(-KEPT_ENTRIES))

  const forked = await $.model.fork({ prompt: `${ASIDE_PROMPT}\n${text}` })
  const answered: Pick<AsideEntry, 'answer' | 'isError'> = forked.isAnswered
    ? { answer: forked.text, isError: false }
    : { answer: describeFailure(forked.reason), isError: true }

  await update($, entries, list => list.map(entry => (entry.id === id ? { ...entry, ...answered } : entry)))
}
