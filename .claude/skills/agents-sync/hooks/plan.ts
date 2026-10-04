export type LinkSource = { name: string; path: string }

export type LinkEntry = { name: string; path: string; isLink: boolean; linkTarget?: string; isTargetPresent: boolean }

export type SyncAction =
  | { kind: 'link'; name: string; source: string; link: string }
  | { kind: 'unlink'; name: string; link: string }
  | { kind: 'conflict'; name: string; link: string }

export function planSync(sources: readonly LinkSource[], entries: readonly LinkEntry[], ownRoot: string, linkRoot: string): SyncAction[] {
  const actions: SyncAction[] = []
  const byName = new Map(entries.map(entry => [entry.name, entry]))

  for (const source of sources) {
    const entry = byName.get(source.name)
    const link = `${linkRoot}/${source.name}`
    if (entry === undefined) actions.push({ kind: 'link', name: source.name, source: source.path, link })
    else if (!entry.isLink) actions.push({ kind: 'conflict', name: source.name, link })
    else if (entry.linkTarget !== source.path) {
      if (isOwned(entry, ownRoot)) {
        actions.push({ kind: 'unlink', name: source.name, link })
        actions.push({ kind: 'link', name: source.name, source: source.path, link })
      } else {
        actions.push({ kind: 'conflict', name: source.name, link })
      }
    }
  }

  const wanted = new Set(sources.map(source => source.name))
  for (const entry of entries) {
    if (entry.isLink && !wanted.has(entry.name) && isOwned(entry, ownRoot) && !entry.isTargetPresent) {
      actions.push({ kind: 'unlink', name: entry.name, link: entry.path })
    }
  }

  return actions
}

function isOwned(entry: LinkEntry, ownRoot: string): boolean {
  return entry.linkTarget !== undefined && entry.linkTarget.startsWith(`${ownRoot}/`)
}
