return {
  {
    'folke/edgy.nvim',
    event = 'VeryLazy',
    --enabled = false,
    keys = {
      {
        '<leader>ue',
        function()
          require('edgy').toggle()
        end,
        desc = 'Edgy Toggle',
      },
      {
        '<leader>uE',
        function()
          require('edgy').select()
        end,
        desc = 'Edgy Select Window',
      },
      {
        '<leader>wl',
        function()
          require('edgy').toggle 'right'
        end,
        desc = 'Edgy Toggle Right',
      },
      {
        '<leader>wh',
        function()
          require('edgy').toggle 'left'
        end,
        desc = 'Edgy Toggle Left',
      },
      {
        '<leader>wj',
        function()
          require('edgy').toggle 'bottom'
        end,
        desc = 'Edgy Toggle Bottom',
      },
    },
    opts = function()
      local opts = {
        options = {
          bottom = { size = 0.2 },
          left = { size = 40 },
          right = { size = 40 },
        },
        close_when_all_hidden = false,
        exit_when_last = false,
        animate = {
          enabled = false,
        },
        wo = {
          winbar = true,
          spell = false,
        },
        left = {
          {
            title = 'Explorer',
            ft = 'neo-tree',
            size = { height = 0.5 },
            open = 'Neotree toggle position=left',
            wo = {
              winbar = false,
            },
          },
          {
            title = 'Outline',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'symbols'
            end,
            --open = 'Trouble symbols toggle focus=false win.position=left',
          },
        },
        right = {
          {
            ft = 'opencode_output',
            size = { width = 60 },
            wo = {
              winbar = false,
              winhighlight = 'Normal:OpencodeBackground',
            },
          },
          {
            ft = 'opencode',
            size = { height = 0.25 },
            wo = {
              winbar = false,
              winhighlight = 'Normal:OpencodeBackground',
            },
          },
          {
            title = 'LSP (Trouble)',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'lsp'
            end,
            open = 'Trouble lsp toggle focus=false win.position=right',
          },
          {
            title = 'neotest-summary',
            ft = 'neotest-summary',
            open = 'Neotest summary',
            size = { width = 0.20 },
          },
          { title = 'Grug Far', ft = 'grug-far', size = { width = 0.4 } },
        },
        bottom = {
          {
            title = 'LSP Definitions (Trouble)',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'lsp_definitions'
            end,
            open = 'Trouble lsp_definitions toggle restore=true',
          },
          {
            title = 'LSP References (Trouble)',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'lsp_references'
            end,
            open = 'Trouble lsp_references toggle restore=true',
          },
          {
            title = '󱖫 Diagnostics (Trouble)',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'diagnostics'
            end,
            open = 'Trouble diagnostics toggle filter.buf=0',
          },
          {
            title = '󰁨 QuickFix (Trouble)',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'qflist'
            end,
            open = 'Trouble qflist toggle',
          },
          {
            title = 'Local Quickfix (Trouble)',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'loclist'
            end,
            open = 'Trouble loclist toggle',
          },
          {
            title = ' Todo',
            ft = 'trouble',
            filter = function(_, win)
              local win_trouble = vim.w[win].trouble
              return win_trouble and win_trouble.mode == 'todo'
            end,
            open = 'Trouble loclist toggle',
          },
          {
            title = '󰻞 Notifications',
            ft = 'noice',
            filter = function(buf, win)
              local is_not_floating = vim.api.nvim_win_get_config(win).relative == ''
              local is_no_file = vim.bo[buf].buftype == 'nofile'
              return is_no_file and is_not_floating
            end,
            open = 'Noice',
          },
          {
            title = 'neotest-panel',
            ft = 'neotest-output-panel',
            size = { height = 0.25 },
            open = 'Neotest output-panel',
          },
          {
            title = 'overseer',
            ft = 'OverseerList',
            open = 'OverseerToggle!',
            size = { width = 0.15 },
          },
          { ft = 'qf', title = '󰁨 QuickFix' },
          {
            ft = 'help',
            size = { height = 20 },
            -- don't open help files in edgy that we're editing
            filter = function(buf)
              return vim.bo[buf].buftype == 'help'
            end,
          },
          { title = 'Spectre', ft = 'spectre_panel', size = { height = 0.4 } },
          { title = 'Neotest Output', ft = 'neotest-output-panel', size = { height = 15 } },
        },
        keys = {
          -- increase width
          ['<c-Right>'] = function(win)
            win:resize('width', 2)
          end,
          -- decrease width
          ['<c-Left>'] = function(win)
            win:resize('width', -2)
          end,
          -- increase height
          ['<c-Up>'] = function(win)
            win:resize('height', 2)
          end,
          -- decrease height
          ['<c-Down>'] = function(win)
            win:resize('height', -2)
          end,
        },
      }

      for _, pos in ipairs { 'top', 'bottom', 'left', 'right' } do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = 'trouble',
          filter = function(_, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.position == pos
              and vim.w[win].trouble.type == 'split'
              and vim.w[win].trouble.relative == 'editor'
              and not vim.w[win].trouble_preview
          end,
        })

        table.insert(opts[pos], {
          ft = 'snacks_terminal',
          size = { height = 0.4 },
          title = '%{b:snacks_terminal.id}: %{b:term_title}',
          filter = function(_, win)
            return vim.w[win].snacks_win
              and vim.w[win].snacks_win.position == pos
              and vim.w[win].snacks_win.relative == 'editor'
              and not vim.w[win].trouble_preview
          end,
        })
      end
      return opts
    end,
  },
  {
    'lucobellic/edgy-group.nvim',
    dependencies = { 'folke/edgy.nvim' },
    keys = {
      {
        '<leader>;',
        function()
          require('edgy-group.stl').pick()
        end,
        desc = 'Edgy Group Pick',
        mode = { 'n', 'v' },
      },
    },
    opts = {
      groups = {
        left = {
          { icon = ' ', titles = { 'Explorer', 'Outline' }, pick_key = 'e' },
          { icon = 'AI ', titles = { 'opencode_output', 'opencode' }, pick_key = 'a' },
        },
      },
      statusline = {
        clickable = true,
        colored = true,
        colors = {
          active = 'Identifier',
          inactive = 'Directory',
          pick_active = 'FlashLabel',
          pick_inactive = 'FlashLabel',
        },
        pick_key_pose = 'right_separator',
        pick_function = function(key)
          -- Use upper case to focus all element of the selected group while closing other (disable toggle)
          local toggle = not key:match '%u'
          local edgy_group = require 'edgy-group'
          for _, group in ipairs(edgy_group.get_groups_by_key(key:lower())) do
            pcall(edgy_group.open_group_index, group.position, group.index, toggle)
          end
        end,
      },
    },
    config = function(_, opts)
      require('edgy-group').setup(opts)
    end,
  },
}
