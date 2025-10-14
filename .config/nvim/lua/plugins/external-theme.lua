-- External theme switcher for system-wide theme integration
-- This plugin allows changing Neovim colorschemes from outside of Neovim
-- while keeping all existing themes available for instant switching

return {
  dir = vim.fn.expand '~/.config/nvim/lua/plugins',
  name = 'external-theme',
  priority = 1500, -- Higher priority than colorschemes to ensure it loads after them
  config = function()
    local external_theme_file = vim.fn.expand '~/.config/themes/_generated/nvim.lua'

    -- Function to apply external theme
    local function apply_external_theme()
      if vim.fn.filereadable(external_theme_file) == 1 then
        local success, err = pcall(dofile, external_theme_file)
        if not success then
          vim.notify('Error loading external theme: ' .. tostring(err), vim.log.levels.WARN)
          return
        else
          vim.notify('External theme reloaded', vim.log.levels.INFO)
        end
      else
        vim.notify('Theme config not found: ' .. external_theme_file, vim.log.levels.INFO)
        vim.cmd 'colorscheme nordfox'
      end
    end

    -- Apply external theme on startup
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        apply_external_theme()
      end,
    })

    -- Manual reload command
    vim.api.nvim_create_user_command('ReloadExternalTheme', function()
      apply_external_theme()
    end, { desc = 'Reload external theme configuration' })

    -- Set up SIGUSR1 handler using vim.loop
    local uv = vim.loop
    local signal = uv.new_signal()
    uv.signal_start(signal, 'sigusr1', function()
      vim.schedule(function()
        vim.defer_fn(apply_external_theme, 50)
      end)
    end)
  end,
}
