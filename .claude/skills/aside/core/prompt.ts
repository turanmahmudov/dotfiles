export const ASIDE_PROMPT = [
  'The user asks a side question about this session. The answer is shown in a side pane and does not enter the main conversation.',
  'Answer from what the conversation already holds. Be short and direct. Do not plan new work or claim that you will do anything.',
  '',
  'Question:',
].join('\n')

export function describeFailure(reason: string): string {
  if (reason === 'nothing-to-fork') return 'The session has no reply yet, so there is nothing to ask about.'
  if (reason === 'aborted') return 'The question was stopped before it was answered.'

  return `The question failed: ${reason}.`
}
