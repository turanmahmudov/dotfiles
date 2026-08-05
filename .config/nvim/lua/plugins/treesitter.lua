local parsers = {
  'bash',
  'c',
  'diff',
  'html',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'vim',
  'vimdoc',
  'go',
  'gomod',
  'gowork',
  'gosum',
  'php',
  'python',
  'ruby',
  'rust',
  'javascript',
  'typescript',
  'yaml',
  'zig',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    init = function()
      local ts = require 'nvim-treesitter'
      local installed = require('nvim-treesitter.config').get_installed()
      local to_install = vim
        .iter(parsers)
        :filter(function(parser)
          return not vim.tbl_contains(installed, parser)
        end)
        :totable()
      if #to_install > 0 then
        ts.install(to_install)
      end

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  { -- split-join
    'Wansmer/treesj',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    keys = {
      { '<leader>m', '<cmd>TSJToggle<cr>', desc = 'Split/Join Toggle' },
      { '<leader>rj', '<cmd>TSJJoin<cr>', desc = 'Join Node' },
      { '<leader>rs', '<cmd>TSJSplit<cr>', desc = 'Split Node' },
    },
    opts = {
      use_default_keymaps = false,
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
