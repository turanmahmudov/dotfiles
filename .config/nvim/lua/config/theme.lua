-- External theme switcher for system-wide theme integration
-- The generated file is written by the theme tool outside of Neovim.
-- SIGUSR1 tells a running instance to re-read it.

local generated_theme_file = vim.fn.expand '~/.config/themes/_generated/nvim.lua'

local function applyExternalTheme()
  if vim.fn.filereadable(generated_theme_file) == 0 then
    vim.notify('Theme config not found: ' .. generated_theme_file, vim.log.levels.INFO)
    vim.cmd 'colorscheme nordfox'
    return
  end

  local success, err = pcall(dofile, generated_theme_file)
  if not success then
    vim.notify('Error loading external theme: ' .. tostring(err), vim.log.levels.WARN)
  else
    vim.notify('External theme reloaded', vim.log.levels.INFO)
  end
end

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('external-theme', { clear = true }),
  callback = applyExternalTheme,
})

vim.api.nvim_create_user_command('ReloadExternalTheme', applyExternalTheme, {
  desc = 'Reload external theme configuration',
})

local signal = vim.uv.new_signal()
vim.uv.signal_start(signal, 'sigusr1', function()
  vim.schedule(function()
    vim.defer_fn(applyExternalTheme, 50)
  end)
end)
