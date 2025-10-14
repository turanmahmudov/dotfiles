return {
  { -- Override delete op to delete, add additional cut key
    'gbprod/cutlass.nvim',
    event = 'BufReadPost',
    opts = {
      cut_key = 'x',
      override_del = true,
      exclude = {},
      registers = {
        select = '_',
        delete = '_',
        change = '_',
      },
    },
  },
}
