local function get_picker_layout()
  if vim.o.columns >= 120 then
    -- Telescope layout
    return {
      reverse = true,
      layout = {
        box = 'horizontal',
        backdrop = false,
        width = 0.8,
        height = 0.9,
        border = 'none',
        {
          box = 'vertical',
          { win = 'list', title = ' Results ', title_pos = 'center', border = true },
          { win = 'input', height = 1, border = true, title = '{title} {live} {flags}', title_pos = 'center' },
        },
        {
          win = 'preview',
          title = '{preview:Preview}',
          width = 0.45,
          border = true,
          title_pos = 'center',
        },
      },
    }
  else
    -- Vertical layout
    return {
      layout = {
        backdrop = false,
        width = 0.5,
        min_width = 80,
        height = 0.8,
        min_height = 30,
        box = 'vertical',
        border = true,
        title = '{title} {live} {flags}',
        title_pos = 'center',
        { win = 'preview', title = '{preview}', height = 0.4, border = 'bottom' },
        { win = 'list', border = 'none' },
        { win = 'input', height = 1, border = 'top' },
      },
    }
  end
end

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      toggle = { enabled = true },
      gitbrowse = { enabled = true },
      input = { enabled = true },
      lazygit = { enabled = true },
      picker = {
        enabled = true,
        layout = get_picker_layout,
        matcher = {
          frecency = true,
        },
      },
      indent = {
        enabled = true,
        indent = { char = '│' },
        scope = { char = '│', underline = true },
      },
      statuscolumn = {
        enabled = true,
        left = { 'mark', 'sign' },
        right = { 'fold', 'git' },
        folds = {
          open = true,
          git_hl = true,
        },
      },
    },
    keys = {
      -- Terminal
      {
        '<leader>tt',
        function()
          Snacks.terminal.toggle(nil, { win = { position = 'bottom' } })
        end,
        desc = 'Terminal (bottom)',
      },
      {
        '<leader>tf',
        function()
          -- Snacks keys terminals by cmd, cwd, env and count, not by position,
          -- so the float needs its own count to be a separate instance
          Snacks.terminal.toggle(nil, { win = { position = 'float' }, count = 2 })
        end,
        desc = 'Terminal (float)',
      },
      {
        '<leader>gb',
        function()
          Snacks.gitbrowse()
        end,
        desc = 'Git Browse',
        mode = { 'n', 'v' },
      },
      {
        '<leader>gg',
        function()
          Snacks.lazygit()
        end,
        desc = 'Lazygit',
      },
      {
        '<leader>gr',
        function()
          Snacks.terminal(vim.env.GIT_REVIEW or 'tuicr -w', { win = { position = 'float' } })
        end,
        desc = 'Review Diff',
      },
      -- Picker
      {
        '<leader>sh',
        function()
          Snacks.picker.help()
        end,
        desc = 'Search Help',
      },
      {
        '<leader>sk',
        function()
          Snacks.picker.keymaps()
        end,
        desc = 'Search Keymaps',
      },
      {
        '<leader>s.',
        function()
          Snacks.picker()
        end,
        desc = 'Search Builtin',
      },
      {
        '<leader>sd',
        function()
          Snacks.picker.diagnostics()
        end,
        desc = 'Search Diagnostics',
      },
      {
        '<leader>sR',
        function()
          Snacks.picker.resume()
        end,
        desc = 'Search Resume',
      },
      {
        '<leader><leader>',
        function()
          Snacks.picker.buffers()
        end,
        desc = 'Find buffers',
      },
      {
        '<leader>sb',
        function()
          Snacks.picker.lines()
        end,
        desc = 'Buffer Lines',
      },
      {
        '<leader>sB',
        function()
          Snacks.picker.grep_buffers()
        end,
        desc = 'Grep Open Buffers',
      },
      {
        '<leader>sf',
        function()
          Snacks.picker.files()
        end,
        desc = 'Find Files',
      },
      {
        '<leader>sg',
        function()
          Snacks.picker.grep()
        end,
        desc = 'Grep',
      },
      {
        '<leader>sw',
        function()
          Snacks.picker.grep_word()
        end,
        desc = 'Visual selection or word',
        mode = { 'n', 'x' },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
          Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
          Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
          Snacks.toggle.line_number():map '<leader>ul'
          Snacks.toggle.diagnostics():map '<leader>ud'
          Snacks.toggle.treesitter():map '<leader>uT'
          -- Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
          Snacks.toggle.inlay_hints():map '<leader>uh'
          Snacks.toggle.indent():map '<leader>ug'
        end,
      })
    end,
  },
}
