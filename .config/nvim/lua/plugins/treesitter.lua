return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    main = 'nvim-treesitter',
    opts = {
      ensure_installed = {
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
        'ruby',
        'rust',
        'javascript',
        'typescript',
        'zig',
      },
      auto_install = true,
    },
    init = function()
      local ensure_installed = {
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
        'ruby',
        'rust',
        'javascript',
        'typescript',
        'zig',
      }
      local ts = require 'nvim-treesitter'
      local config = require 'nvim-treesitter.config'
      local installed = config.get_installed()
      local to_install = vim.iter(ensure_installed)
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
    opts = {},
    config = function(_, opts)
      require('treesj').setup(opts)
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
