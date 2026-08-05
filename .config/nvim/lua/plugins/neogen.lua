return {
  -- Annotation generator
  {
    'danymat/neogen',
    cmd = 'Neogen',
    keys = {
      { '<leader>rd', '<cmd>Neogen<cr>', desc = 'Generate Annotation' },
    },
    config = true,
    -- Uncomment next line if you want to follow only stable versions
    -- version = "*"
  },
}
