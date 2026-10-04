import type { CodeBlock } from '../types'

const FENCE = /^([ \t]*)(`{3,}|~{3,})([^\n`]*)\n([\s\S]*?)\n[ \t]*\2[ \t]*$/gm

export function parseCodeBlocks(text: string): CodeBlock[] {
  return [...text.matchAll(FENCE)].map(match => ({
    language: (match[3] ?? '').trim().split(/\s+/)[0] ?? '',
    source: stripIndent(match[4] ?? '', match[1] ?? ''),
  }))
}

export function describeBlock(block: CodeBlock): string {
  const firstLine = block.source.split('\n').find(line => line.trim() !== '')?.trim() ?? ''
  const lineCount = block.source.split('\n').length
  const language = block.language === '' ? 'text' : block.language

  return `${language}, ${lineCount} ${lineCount === 1 ? 'line' : 'lines'}: ${firstLine}`
}

function stripIndent(source: string, indent: string): string {
  if (indent === '') return source

  return source
    .split('\n')
    .map(line => (line.startsWith(indent) ? line.slice(indent.length) : line))
    .join('\n')
}
