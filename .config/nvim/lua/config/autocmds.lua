-- For line marker
local augroup = vim.api.nvim_create_augroup -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- Create autocommand

-- Set line marker to 120 for PHP
augroup('setLineLength', { clear = true })
autocmd('Filetype', {
  group = 'setLineLength',
  pattern = { 'php' },
  command = 'setlocal cc=120',
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
