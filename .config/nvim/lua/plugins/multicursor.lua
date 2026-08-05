return {
  { -- Multiple cursors, in the style of the Ctrl-D flow in other editors
    'jake-stewart/multicursor.nvim',
    branch = '1.0',
    event = 'BufReadPost',
    config = function()
      local mc = require 'multicursor-nvim'
      mc.setup()

      local map = vim.keymap.set

      -- Add or skip a cursor on the next/previous match of the word or selection
      map({ 'n', 'x' }, '<C-n>', function()
        mc.matchAddCursor(1)
      end, { desc = 'Add Cursor at Next Match' })
      map({ 'n', 'x' }, '<C-p>', function()
        mc.matchAddCursor(-1)
      end, { desc = 'Add Cursor at Previous Match' })
      map({ 'n', 'x' }, '<A-n>', function()
        mc.matchSkipCursor(1)
      end, { desc = 'Skip Next Match' })
      map({ 'n', 'x' }, '<A-p>', function()
        mc.matchSkipCursor(-1)
      end, { desc = 'Skip Previous Match' })

      -- Add a cursor on the line above or below
      map('n', '<A-Up>', function()
        mc.lineAddCursor(-1)
      end, { desc = 'Add Cursor Line Above' })
      map('n', '<A-Down>', function()
        mc.lineAddCursor(1)
      end, { desc = 'Add Cursor Line Below' })

      -- Every match in the buffer, or in the visual selection
      map({ 'n', 'x' }, '<leader>A', mc.matchAllAddCursors, { desc = 'Add Cursors to All Matches' })

      map('n', '<A-LeftMouse>', mc.handleMouse, { desc = 'Toggle Cursor at Mouse' })
      map('n', '<A-LeftDrag>', mc.handleMouseDrag, { desc = 'Drag Cursors' })
      map('n', '<A-LeftRelease>', mc.handleMouseRelease, { desc = 'Release Dragged Cursors' })

      -- These only bind while more than one cursor exists, so <Esc> keeps
      -- clearing the search highlight the rest of the time
      mc.addKeymapLayer(function(layerSet)
        layerSet({ 'n', 'x' }, '<Left>', mc.prevCursor)
        layerSet({ 'n', 'x' }, '<Right>', mc.nextCursor)
        layerSet('n', '<Esc>', function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)
    end,
  },
}
