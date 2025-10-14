return {
  { -- AI suggestions / autocomplete
    'milanglacier/minuet-ai.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'hrsh7th/nvim-cmp' }, -- optional
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
            end_point = os.getenv 'MISTRAL_BASE_URL' .. '/v1/fim/completions',
            api_key = 'MISTRAL_API_KEY',
          },
        },
      }
    end,
  },
  { -- OpenCode frontend
    'sudo-tee/opencode.nvim',
    opts = {
      ui = {
        input = {
          min_height = 0.25,
          max_height = 0.25,
        },
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          anti_conceal = { enabled = false },
          file_types = { 'markdown', 'opencode_output' },
        },
        ft = { 'markdown', 'Avante', 'copilot-chat', 'opencode_output' },
      },
      'hrsh7th/nvim-cmp',
      'folke/snacks.nvim',
    },
  },
}
