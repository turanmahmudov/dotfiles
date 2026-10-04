const READ_ONLY_TOOLS = new Set([
  'Read', 'Glob', 'Grep', 'LSP', 'WebFetch', 'WebSearch', 'ToolSearch', 'TodoWrite', 'Skill', 'Agent',
  'AskUserQuestion', 'ListMcpResourcesTool', 'ReadMcpResourceTool', 'ReadMcpResourceDirTool',
  'ReadNotifications', 'TaskOutput', 'EnterPlanMode', 'ExitPlanMode',
])

const READ_ONLY_COMMANDS = new Set([
  'ls', 'cat', 'head', 'tail', 'less', 'wc', 'grep', 'rg', 'egrep', 'fgrep', 'jq', 'yq', 'cut', 'sort', 'uniq',
  'tr', 'column', 'diff', 'cmp', 'file', 'stat', 'du', 'df', 'pwd', 'echo', 'printf', 'which', 'whereis', 'type',
  'date', 'env', 'printenv', 'id', 'whoami', 'uname', 'hostname', 'ps', 'pgrep', 'tree', 'basename', 'dirname',
  'realpath', 'readlink', 'true', 'false', 'test', '[', 'cd', 'nl', 'fold', 'base64', 'sha256sum', 'md5sum', 'zcat',
])

const GIT_READ = new Set([
  'status', 'log', 'diff', 'show', 'rev-parse', 'rev-list', 'ls-files', 'ls-remote', 'blame', 'fetch', 'describe',
  'shortlog', 'grep', 'cat-file', 'merge-base', 'show-ref', 'for-each-ref', 'name-rev', 'whatchanged',
])

const GH_READ: Record<string, Set<string>> = {
  pr: new Set(['view', 'list', 'checks', 'diff', 'status']),
  issue: new Set(['view', 'list', 'status']),
  run: new Set(['view', 'list', 'watch']),
  repo: new Set(['view', 'list']),
  release: new Set(['view', 'list']),
  workflow: new Set(['view', 'list']),
  search: new Set(['code', 'issues', 'prs', 'repos', 'commits']),
  auth: new Set(['status']),
}

const MCP_READ_WORDS = new Set([
  'get', 'list', 'search', 'read', 'query', 'describe', 'fetch', 'lookup', 'explain', 'validate', 'resolve', 'ask',
  'info', 'view', 'show', 'find',
])

const MCP_WRITE_WORDS = new Set([
  'create', 'update', 'delete', 'add', 'send', 'edit', 'transition', 'set', 'write', 'post', 'remove', 'schedule',
  'plan', 'complete', 'authenticate', 'upload', 'move', 'merge', 'close', 'assign',
])

export function isReadOnlyTool(tool: string, input: Record<string, unknown>): boolean {
  if (READ_ONLY_TOOLS.has(tool)) return true
  if (tool === 'Bash') return typeof input.command === 'string' && isReadOnlyCommand(input.command)
  if (tool.startsWith('mcp__')) return isReadOnlyMcpTool(tool)

  return false
}

export function isReadOnlyMcpTool(tool: string): boolean {
  const name = tool.split('__').pop() ?? ''
  const words = name
    .replace(/([a-z])([A-Z])/g, '$1_$2')
    .toLowerCase()
    .split(/[_-]+/)

  return words.some(word => MCP_READ_WORDS.has(word)) && !words.some(word => MCP_WRITE_WORDS.has(word))
}

export function isReadOnlyCommand(command: string): boolean {
  if (command.includes('`') || /<<|<\(|>\(/.test(command)) return false

  const withoutSafeRedirects = command.replace(/\d?>&\d|\d?>\s*\/dev\/null/g, ' ')
  if (withoutSafeRedirects.includes('>')) return false

  const segments = withoutSafeRedirects
    .replace(/\$\(/g, ';')
    .replace(/\)/g, ';')
    .split(/&&|\|\||[;|\n&]/)
    .map(segment => segment.trim())
    .filter(segment => segment !== '')

  return segments.length > 0 && segments.every(isReadOnlySegment)
}

function isReadOnlySegment(segment: string): boolean {
  const words = splitWords(segment)
  while (words.length > 0 && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[0] ?? '')) words.shift()

  const [program = '', ...args] = words
  const name = program.split('/').pop() ?? ''

  if (READ_ONLY_COMMANDS.has(name)) return true
  if (name === 'sed') return !args.some(arg => /^-[a-zA-Z]*i/.test(arg) || arg.startsWith('--in-place'))
  if (name === 'awk') return !/system\s*\(|getline|print\s*>/.test(segment)
  if (name === 'find') return !args.some(arg => /^-(delete|exec|execdir|ok|okdir|fprint|fprintf|fls)$/.test(arg))
  if (name === 'xargs') return isReadOnlySegment(args.filter(arg => !arg.startsWith('-')).join(' '))
  if (name === 'git') return isReadOnlyGit(args)
  if (name === 'gh') return isReadOnlyGh(args)
  if (name === 'docker') return isReadOnlyDocker(args)
  if (name === 'kubectl') return ['get', 'describe', 'logs', 'top', 'explain', 'version', 'api-resources'].includes(args[0] ?? '')
  if (name === 'aws') return args.some(arg => /^(describe|list|get)-/.test(arg) || arg === 'ls') && !args.includes('get-secret-value')
  if (name === 'curl') return !args.some(arg => /^(-X|--request|-d|--data.*|-F|--form|-T|--upload-file|-o|--output|-O|--remote-name)$/.test(arg))
  if (name === 'composer') return ['show', 'outdated', 'why', 'why-not', 'licenses', 'validate'].includes(args[0] ?? '')
  if (name === 'npm') return ['ls', 'list', 'view', 'outdated', 'why'].includes(args[0] ?? '')
  if (name === 'mise') return ['ls', 'list', 'current', 'which', 'where'].includes(args[0] ?? '')

  return false
}

function isReadOnlyGit(args: string[]): boolean {
  const rest = [...args]
  while (rest[0] === '-C' || rest[0] === '-c') rest.splice(0, 2)
  while ((rest[0] ?? '').startsWith('--')) rest.shift()
  const [subcommand = '', ...options] = rest

  if (GIT_READ.has(subcommand)) return true
  if (subcommand === 'branch') return !options.some(option => /^(-[dDmMcC]|--delete|--move|--copy|--set-upstream-to|-u|--unset-upstream|--edit-description)/.test(option)) && options.every(option => option.startsWith('-'))
  if (subcommand === 'remote') return options.length === 0 || options[0] === '-v' || options[0] === 'show' || options[0] === 'get-url'
  if (subcommand === 'tag') return options.length === 0 || options.every(option => ['-l', '--list', '-n'].includes(option) || option.startsWith('--sort') || option.startsWith('--contains'))
  if (subcommand === 'stash') return options[0] === 'list' || options[0] === 'show'
  if (subcommand === 'config') return options.some(option => ['--get', '--get-all', '--list', '-l', '--get-regexp'].includes(option))
  if (subcommand === 'worktree') return options[0] === 'list'
  if (subcommand === 'reflog') return options.length === 0 || options[0] === 'show'

  return false
}

function isReadOnlyGh(args: string[]): boolean {
  const [group = '', action = ''] = args

  if (group === 'api') {
    const methodIndex = args.findIndex(arg => arg === '-X' || arg === '--method')
    const method = methodIndex === -1 ? 'GET' : (args[methodIndex + 1] ?? '').toUpperCase()
    const hasBody = args.some(arg => /^(-f|-F|--field|--raw-field|--input)$/.test(arg))

    return method === 'GET' && !hasBody && !args.some(arg => arg.includes('graphql'))
  }

  return GH_READ[group]?.has(action) ?? false
}

function isReadOnlyDocker(args: string[]): boolean {
  const [first = '', second = ''] = args
  if (first === 'compose') return ['ps', 'logs', 'config', 'images', 'ls', 'top'].includes(second)

  return ['ps', 'logs', 'inspect', 'images', 'version', 'info', 'top', 'port', 'history'].includes(first)
    || (first === 'stats' && args.includes('--no-stream'))
}

function splitWords(segment: string): string[] {
  return [...segment.matchAll(/"([^"]*)"|'([^']*)'|(\S+)/g)].map(match => match[1] ?? match[2] ?? match[3] ?? '')
}
