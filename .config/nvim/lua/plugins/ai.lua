local ai_proxy_base_url = os.getenv 'AI_PROXY_BASE_URL'

return {
  { -- AI suggestions / autocomplete
    'milanglacier/minuet-ai.nvim',
    enabled = ai_proxy_base_url ~= nil,
    lazy = true, -- loaded by nvim-cmp, which lists it as a dependency
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>av', '<cmd>Minuet virtualtext toggle<cr>', desc = 'Toggle Virtual Text' },
      { '<leader>ac', '<cmd>Minuet cmp toggle<cr>', desc = 'Toggle Completion Source' },
    },
    config = function()
      require('minuet').setup {
        cmp = {
          enable_auto_complete = false,
        },
        virtualtext = {
          keymap = {
            accept = '<A-a>',
            accept_line = '<A-A>',
            accept_n_lines = '<A-z>',
            prev = '<A-[>',
            next = '<A-]>',
            dismiss = '<A-e>',
          },
        },
        provider = 'codestral',
        provider_options = {
          codestral = {
            end_point = ai_proxy_base_url .. '/mistral/v1/fim/completions',
            api_key = 'AI_PROXY_API_KEY',
          },
        },
      }
    end,
  },
}
