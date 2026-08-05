return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },
    opts = {
      completions = { lsp = { enabled = true } },
      -- The gutter already carries fold, diagnostic and git signs
      sign = { enabled = false },
      heading = {
        width = 'block',
        left_pad = 1,
        right_pad = 2,
        min_width = 40,
      },
      code = {
        width = 'block',
        border = 'thin',
        left_pad = 2,
        right_pad = 2,
        min_width = 60,
        language_pad = 1,
      },
      pipe_table = {
        preset = 'round',
      },
      -- No latex parser and no utftex or latex2text on PATH
      latex = { enabled = false },
    },
  },
}
