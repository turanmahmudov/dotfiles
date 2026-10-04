import type { PrCheck, PrCheckBucket, PrSource, TrackedPr } from '../types'

const PR_URL = /https:\/\/github\.com\/([\w.-]+\/[\w.-]+)\/pull\/(\d+)/
const ACTIONS_JOB = /github\.com\/([\w.-]+\/[\w.-]+)\/actions\/runs\/\d+\/job\/(\d+)/

type RollupEntry = {
  __typename?: string
  name?: string
  context?: string
  status?: string
  conclusion?: string
  state?: string
  detailsUrl?: string
  targetUrl?: string
}

type PrView = { url: string; number: number; title: string; state: string; statusCheckRollup?: RollupEntry[] | null }

export function findPrUrl(text: string): string | undefined {
  return text.match(PR_URL)?.[0]
}

export function findActionsJob(link: string): { repo: string; jobId: string } | undefined {
  const match = link.match(ACTIONS_JOB)

  return match === null ? undefined : { repo: match[1] ?? '', jobId: match[2] ?? '' }
}

export function parsePrView(json: string, source: PrSource): TrackedPr {
  const view = JSON.parse(json) as PrView

  return {
    source,
    url: view.url,
    repo: view.url.match(PR_URL)?.[1] ?? '',
    number: view.number,
    title: view.title,
    state: view.state,
    checks: (view.statusCheckRollup ?? []).map(mapRollupEntry),
  }
}

export function resolvePrBucket(pr: TrackedPr): PrCheckBucket | 'none' {
  if (pr.checks.length === 0) return 'none'
  if (pr.checks.some(check => check.bucket === 'fail')) return 'fail'
  if (pr.checks.some(check => check.bucket === 'pending')) return 'pending'

  return 'pass'
}

export function findNewFailures(before: TrackedPr | undefined, after: TrackedPr): PrCheck[] {
  const failedBefore = new Set((before?.checks ?? []).filter(check => check.bucket === 'fail').map(check => check.name))

  return after.checks.filter(check => check.bucket === 'fail' && !failedBefore.has(check.name))
}

function mapRollupEntry(entry: RollupEntry): PrCheck {
  if (entry.__typename === 'StatusContext') {
    return { name: entry.context ?? '', bucket: mapStatusState(entry.state ?? ''), link: entry.targetUrl ?? '' }
  }

  return { name: entry.name ?? '', bucket: mapCheckRun(entry.status ?? '', entry.conclusion ?? ''), link: entry.detailsUrl ?? '' }
}

function mapStatusState(state: string): PrCheckBucket {
  if (state === 'SUCCESS') return 'pass'
  if (state === 'FAILURE' || state === 'ERROR') return 'fail'

  return 'pending'
}

function mapCheckRun(status: string, conclusion: string): PrCheckBucket {
  if (status !== 'COMPLETED') return 'pending'
  if (conclusion === 'SUCCESS' || conclusion === 'NEUTRAL') return 'pass'
  if (conclusion === 'SKIPPED') return 'skip'

  return 'fail'
}

export function parsePrUrls(json: string): string[] {
  return (JSON.parse(json) as { url: string }[]).map(pr => pr.url)
}

export const PR_FIELDS = 'url,number,title,state,statusCheckRollup'

export const LOG_LINES = 150

export const ICONS: Record<PrCheckBucket | 'none', string> = { pass: '✓', fail: '✗', pending: '…', skip: '-', none: ' ' }

export type PrNotice = { text: string; timeoutMs?: number }

export function buildPrLabel(pr: TrackedPr): string {
  return `${pr.repo.split('/')[1]}#${pr.number}`
}

export function describePrChanges(before: TrackedPr | undefined, fresh: TrackedPr): PrNotice[] {
  const label = buildPrLabel(fresh)
  if (fresh.state !== 'OPEN') return before === undefined ? [] : [{ text: `${label} is ${fresh.state.toLowerCase()}.` }]

  const notices: PrNotice[] = findNewFailures(before, fresh).map(check => ({ text: `✗ ${label}: ${check.name} failed`, timeoutMs: 8_000 }))
  if (before !== undefined && resolvePrBucket(before) === 'pending' && resolvePrBucket(fresh) === 'pass') notices.push({ text: `✓ ${label}: all checks passed` })

  return notices
}

export function buildLogArgv(check: PrCheck): string[] | undefined {
  const job = findActionsJob(check.link)

  return job === undefined ? undefined : ['gh', 'run', 'view', '--repo', job.repo, '--job', job.jobId, '--log-failed']
}

export function buildFailureText(pr: TrackedPr, check: PrCheck, log?: string): string {
  const heading = `CI check "${check.name}" failed on ${pr.repo}#${pr.number} (${check.link}).`
  if (log === undefined || log.trim() === '') return `${heading}\n`

  const tail = log.trimEnd().split('\n').slice(-LOG_LINES).join('\n')

  return `${heading} Failed steps, last ${LOG_LINES} lines:\n\`\`\`\n${tail}\n\`\`\`\n`
}

export const GROUPS: { source: PrSource; title: string }[] = [
  { source: 'session', title: 'This session' },
  { source: 'repo', title: 'This repo' },
]
