-- For line marker
local augroup = vim.api.nvim_create_augroup -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- Create autocommand

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Drop the cached fold provider so it is resolved again for the buffer
autocmd({ 'LspAttach', 'LspDetach', 'FileType' }, {
  group = augroup('fold-provider', { clear = true }),
  callback = function(args)
    vim.b[args.buf].fold_provider = nil
  end,
})

-- Set line marker to 120 for PHP
augroup('setLineLength', { clear = true })
autocmd('Filetype', {
  group = 'setLineLength',
  pattern = { 'php' },
  command = 'setlocal cc=120',
})

-- Prose settings for markdown
augroup('setProseOptions', { clear = true })
autocmd('FileType', {
  group = 'setProseOptions',
  pattern = { 'markdown' },
  callback = function()
    vim.opt_local.linebreak = true
    vim.opt_local.list = false
    vim.b.snacks_indent = false
  end,
})

-- Organize imports before writing, for servers that offer the code action.
-- Go is already covered by goimports in conform.
augroup('organizeImportsOnSave', { clear = true })
autocmd('BufWritePre', {
  group = 'organizeImportsOnSave',
  callback = function(args)
    if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
      return
    end
    require('config.imports').organizeImports(args.buf)
  end,
})

-- Show linters for the current buffer's file type
vim.api.nvim_create_user_command('LintInfo', function()
  local filetype = vim.bo.filetype
  local linters = require('lint').linters_by_ft[filetype]

  if linters then
    print('Linters for ' .. filetype .. ': ' .. table.concat(linters, ', '))
  else
    print('No linters configured for filetype: ' .. filetype)
  end
end, {})

-- Enable/Disable formatter
vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = 'Disable autoformat-on-save',
  bang = true,
})
vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = 'Re-enable autoformat-on-save',
})

vim.api.nvim_create_user_command('FileNameToPanel', function()
  vim.system { 'tmux', 'send-keys', '-t', '2', 'File: ' .. vim.api.nvim_buf_get_name(0) }
end, {})
