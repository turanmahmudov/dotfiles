import type { EngineInterface, Register } from 'claude-code'

import { planSync } from './plan'
import type { LinkEntry, LinkSource } from './plan'

const SOURCE_KINDS = [{ dir: '.agents/skills', marker: 'SKILL.md' }]

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const summary = await syncLinks($).catch(error => `agents-sync failed: ${error instanceof Error ? error.message : String(error)}`)
    if (summary !== '') $.ui.toast(summary, { timeoutMs: 8_000 })

    return result
  })
}

async function syncLinks($: EngineInterface): Promise<string> {
  const home = await $.env.get('HOME')
  if (home === undefined || home === '') return 'agents-sync: HOME is not set.'

  const ownRoot = `${home}/.agents`
  const linkRoot = `${home}/.claude/skills`
  const sources = await findSources($, home)
  const entries = await findEntries($, linkRoot)
  const actions = planSync(sources, entries, ownRoot, linkRoot)

  let linked = 0
  let removed = 0
  const conflicts: string[] = []
  for (const action of actions) {
    if (action.kind === 'conflict') {
      conflicts.push(action.name)
      continue
    }
    const argv = action.kind === 'link' ? ['ln', '-s', action.source, action.link] : ['unlink', action.link]
    const ran = await $.process.run(argv, { timeoutMs: 5_000 })
    if (ran.exitCode !== 0) {
      conflicts.push(`${action.name} (${ran.stderr.trim()})`)
      continue
    }
    if (action.kind === 'link') linked += 1
    else removed += 1
  }

  const parts = [
    linked > 0 ? `linked ${linked}` : '',
    removed > 0 ? `removed ${removed}` : '',
    conflicts.length > 0 ? `skipped ${conflicts.join(', ')}: a real folder or a foreign link is in the way` : '',
  ].filter(part => part !== '')
  if (parts.length === 0) return ''

  return `agents-sync: ${parts.join(', ')}.${linked > 0 ? ' New links load in the next session.' : ''}`
}

async function findSources($: EngineInterface, home: string): Promise<LinkSource[]> {
  const sources: LinkSource[] = []
  for (const kind of SOURCE_KINDS) {
    const root = `${home}/${kind.dir}`
    const listed = await $.fs.list(root).catch(() => [])
    for (const entry of listed) {
      if (entry.kind !== 'dir' || entry.name.startsWith('.')) continue
      if (await $.fs.exists(`${root}/${entry.name}/${kind.marker}`)) sources.push({ name: entry.name, path: `${root}/${entry.name}` })
    }
  }

  return sources
}

async function findEntries($: EngineInterface, linkRoot: string): Promise<LinkEntry[]> {
  const listed = await $.fs.list(linkRoot).catch(() => [])
  const entries: LinkEntry[] = []
  for (const entry of listed) {
    const path = `${linkRoot}/${entry.name}`
    const read = await $.process.run(['readlink', path], { timeoutMs: 5_000 })
    const isLink = read.exitCode === 0
    entries.push({
      name: entry.name,
      path,
      isLink,
      linkTarget: isLink ? read.stdout.trim() : undefined,
      isTargetPresent: isLink ? await $.fs.exists(read.stdout.trim()) : true,
    })
  }

  return entries
}
