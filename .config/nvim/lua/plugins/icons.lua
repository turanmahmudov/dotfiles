return {
  { -- Icon provider for bufferline, lualine, neo-tree and render-markdown
    'echasnovski/mini.icons',
    lazy = true,
    opts = {},
    init = function()
      -- Plugins that ask for nvim-web-devicons get the mini.icons shim instead
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },
}
