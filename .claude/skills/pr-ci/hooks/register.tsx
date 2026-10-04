import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { PrCheck, PrSource, TrackedPr } from '../types'
import { GROUPS, ICONS, PR_FIELDS, buildFailureText, buildLogArgv, describePrChanges, findPrUrl, parsePrUrls, parsePrView, resolvePrBucket } from '../core/github'

const PANE = 'pr-ci'
const REFRESH_MS = 60_000
const REPO_PR_LIMIT = 20
const HOTKEYS = 'fghjklmnpqrstuvwxyz'
const prs = atom({ plugin: 'pr-ci', key: 'tracked' } as const, [])

let isRefreshing = false

export const register: Register = (on, options) => {
  const repoPrAuthor = String(options.repoPrAuthor ?? '@me')

  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'prs',
      description: 'Show the PRs this session created and the open PRs of this repo, with CI checks',
      argumentHint: '[pr url]',
    })
    $.clock.after(1_000, () => void refresh($, repoPrAuthor))
    $.clock.every(REFRESH_MS, () => void refresh($, repoPrAuthor))

    return next(e)
  })

  on('command.run', { command: 'prs' }, async ($, e) => {
    const url = findPrUrl(e.args)
    if (url !== undefined) await trackPr($, url, 'session')
    await refresh($, repoPrAuthor)
    if ((await read($, prs)).length === 0) return { text: 'No PRs are tracked. Open one with gh, or run /prs <url>.' }

    await $.ui.open({ id: PANE, title: 'PRs', focus: true })

    return { text: 'PR pane opened.' }
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const ran = await next(e)
    if (!/\bgh\s+pr\s+create\b/.test(e.command) || ran.deny !== undefined) return ran

    const url = findPrUrl(ran.text ?? JSON.stringify(ran.result ?? ''))
    if (url !== undefined) await trackPr($, url, 'session')

    return ran
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const list = await read($, prs)
    const width = Math.max(20, (e.props.bodyColumns ?? 60) - 4)
    const ordered = GROUPS.flatMap(group => list.filter(pr => pr.source === group.source))
    const failedChecks = ordered.flatMap(pr => pr.checks.filter(check => check.bucket === 'fail').map(check => ({ pr, check })))

    return (
      <Box flexDirection="column">
        {GROUPS.map(group => {
          const members = list.filter(pr => pr.source === group.source)

          return (
            <Box key={`group-${group.source}`} flexDirection="column" marginBottom={1}>
              <Text bold underline>{group.title}</Text>
              {members.length === 0 && <Text dimColor>None</Text>}
              {members.map(pr => (
                <Box key={pr.url} flexDirection="column">
                  <Text bold wrap="truncate-end">
                    {ICONS[resolvePrBucket(pr)]} {pr.repo.split('/')[1]}#{pr.number} {pr.title}
                  </Text>
                  {pr.checks.map(check => {
                    const failedIndex = failedChecks.findIndex(failed => failed.pr === pr && failed.check === check)
                    if (failedIndex === -1 || failedIndex >= HOTKEYS.length) {
                      return (
                        <Text key={`${pr.url}-${check.name}`} dimColor={check.bucket !== 'fail'} wrap="truncate-end">
                          {'  '}{ICONS[check.bucket]} {check.name.slice(0, width)}
                        </Text>
                      )
                    }

                    return (
                      <Button
                        key={`fetch-${failedIndex}`}
                        plain
                        hotkey={HOTKEYS[failedIndex]}
                        label={`✗ ${check.name.slice(0, width - 16)} - fetch log`}
                        onPress={async () => {
                          $.ui.toast(`Fetching the log of ${check.name}...`)
                          await $.prompt.fill({ text: await fetchFailureText($, pr, check), mode: 'append' })
                        }}
                      />
                    )
                  })}
                </Box>
              ))}
            </Box>
          )
        })}
      </Box>
    )
  })
}

async function refresh($: EngineInterface, repoPrAuthor: string): Promise<void> {
  if (isRefreshing) return
  isRefreshing = true
  try {
    await syncRepoPrs($, repoPrAuthor)
    for (const pr of await read($, prs)) await refreshPr($, pr.url, pr.source)
  } finally {
    isRefreshing = false
  }
}

async function syncRepoPrs($: EngineInterface, repoPrAuthor: string): Promise<void> {
  const author = repoPrAuthor === '' ? [] : ['--author', repoPrAuthor]
  const listed = await $.process
    .run(['gh', 'pr', 'list', '--state', 'open', ...author, '--limit', String(REPO_PR_LIMIT), '--json', 'url'], { cwd: await $.session.root(), timeoutMs: 20_000 })
    .catch(() => undefined)
  if (listed === undefined || listed.exitCode !== 0) return

  const urls = parsePrUrls(listed.stdout)
  const known = await read($, prs)
  await update($, prs, list => list.filter(pr => pr.source === 'session' || urls.includes(pr.url)))
  for (const url of urls) {
    if (!known.some(pr => pr.url === url)) await refreshPr($, url, 'repo')
  }
}

async function trackPr($: EngineInterface, url: string, source: PrSource): Promise<void> {
  const isNew = !(await read($, prs)).some(pr => pr.url === url && pr.source === source)
  await refreshPr($, url, source)
  if (isNew && source === 'session' && (await read($, prs)).some(pr => pr.url === url)) void $.ui.open({ id: PANE, title: 'PRs' })
}

async function refreshPr($: EngineInterface, url: string, source: PrSource): Promise<void> {
  const view = await $.process.run(['gh', 'pr', 'view', url, '--json', PR_FIELDS], { timeoutMs: 20_000 }).catch(() => undefined)
  if (view === undefined || view.exitCode !== 0) return

  const before = (await read($, prs)).find(pr => pr.url === url)
  const fresh = parsePrView(view.stdout, before?.source === 'session' ? 'session' : source)
  for (const notice of describePrChanges(before, fresh)) $.ui.toast(notice.text, notice.timeoutMs === undefined ? undefined : { timeoutMs: notice.timeoutMs })

  if (fresh.state !== 'OPEN') {
    await update($, prs, list => list.filter(pr => pr.url !== url))

    return
  }

  await update($, prs, list => (list.some(pr => pr.url === url) ? list.map(pr => (pr.url === url ? fresh : pr)) : [...list, fresh]))
}

async function fetchFailureText($: EngineInterface, pr: TrackedPr, check: PrCheck): Promise<string> {
  const argv = buildLogArgv(check)
  const log = argv === undefined ? undefined : await $.process.run(argv, { timeoutMs: 60_000 }).catch(() => undefined)

  return buildFailureText(pr, check, log !== undefined && log.exitCode === 0 ? log.stdout : undefined)
}
