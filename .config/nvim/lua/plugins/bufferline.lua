return {
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    dependencies = {
      'echasnovski/mini.icons',
    },
    opts = {
      options = {
        separator_style = 'thick',
        diagnostics = 'nvim_lsp',
        always_show_bufferline = true,
        offsets = {
          {
            filetype = 'neo-tree',
            text = 'Explorer',
            highlight = 'Directory',
            text_align = 'center',
          },
          {
            filetype = 'codecompanion',
            text = 'AI Chat',
            highlight = 'Directory',
            text_align = 'center',
          },
        },
        close_command = function(bufnum)
          Snacks.bufdelete.delete(bufnum)
        end,
        indicator = {
          icon = '▎',
          style = 'icon',
        },
        buffer_close_icon = '',
        modified_icon = '●',
        close_icon = '',
        left_trunc_marker = '',
        right_trunc_marker = '',
        max_name_length = 18,
        max_prefix_length = 15,
        tab_size = 10,
        custom_filter = function(bufnr)
          -- filter out filetypes you don't want to see
          local exclude_ft = { 'qf', 'fugitive', 'git', 'trouble', 'checkhealth', 'codecompanion' }
          local cur_ft = vim.bo[bufnr].filetype
          local should_filter = vim.tbl_contains(exclude_ft, cur_ft)

          if should_filter then
            return false
          end

          return true
        end,
        color_icons = true,
      },
    },
    config = function(_, opts)
      require('bufferline').setup(opts)
      vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete' }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
}
