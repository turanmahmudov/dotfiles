local function spell()
  if vim.o.spell then
    return string.format '[SPELL]'
  end

  return ''
end

return {
  { -- statusline
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'echasnovski/mini.icons', 'folke/noice.nvim' },
    opts = {
      options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
        globalstatus = vim.o.laststatus == 3,
        disabled_filetypes = {
          'neo-tree',
          'NeoTree',
          'NVimTree',
          'Outline',
          'alpha',
          'qf',
          'trouble',
          'themery',
          'codecompanion',
          'snacks_dashboard',
        },
        ignore_focus = {
          'dapui_watches',
          'dapui_breakpoints',
          'dapui_scopes',
          'dapui_console',
          'dapui_stacks',
          'dap-repl',
        },
      },
      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              return vim.o.columns < 120 and str:sub(1, 1) or str
            end,
          },
        },
        lualine_b = {
          {
            'branch',
            on_click = function()
              require('fzf-lua').git_branches {}
            end,
          },
          {
            'diff',
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
            on_click = function()
              require('fzf-lua').git_status {}
            end,
          },
        },
        lualine_c = {
          {
            spell,
            color = { fg = '#a7c080' },
          },
          {
            function()
              return table.concat(require('edgy-group.stl').get_statusline 'bottom')
            end,
          },
        },
        lualine_x = {
          {
            require('noice').api.status.mode.get,
            cond = require('noice').api.status.mode.has,
            color = { fg = '#ff9e64' },
          },
          {
            'diagnostics',
            on_click = function()
              vim.cmd 'Trouble diagnostics toggle filter.buf=0'
            end,
          },
          {
            'lsp_status',
            on_click = function()
              vim.cmd 'checkhealth vim.lsp'
            end,
          },
        },
        lualine_y = {
          'filetype',
        },
        lualine_z = {
          'location',
        },
      },
      extensions = { 'neo-tree', 'lazy', 'avante' },
    },
  },
}
