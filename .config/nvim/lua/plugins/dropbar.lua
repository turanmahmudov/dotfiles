return {
  {
    'Bekaboo/dropbar.nvim',
    event = 'VeryLazy',
    opts = {
      icons = {
        enable = true,
        ui = {
          bar = {
            separator = ' > ',
            extends = '…',
          },
        },
      },
      bar = {
        sources = function(buf, win)
          local sources = require 'dropbar.sources'
          local utils = require 'dropbar.utils'

          -- Create condensed path source that shows full path as single component
          local path_source = {
            get_symbols = function(buf, win, cursor)
              local symbols = sources.path.get_symbols(buf, win, cursor)

              if #symbols == 0 then
                return {}
              end

              -- Combine all path components into a single symbol
              local path_parts = {}
              for _, symbol in ipairs(symbols) do
                table.insert(path_parts, symbol.name)
              end

              -- Create a single condensed path symbol
              local full_path = table.concat(path_parts, '/')
              local condensed_symbol = symbols[1]:merge {
                name = full_path,
                icon = '',
                on_click = false,
              }

              return { condensed_symbol }
            end,
          }

          if vim.bo[buf].ft == 'markdown' then
            return {
              path_source,
              utils.source.fallback {
                sources.markdown,
                sources.lsp,
              },
            }
          end

          if vim.bo[buf].buftype == 'terminal' then
            return {
              sources.terminal,
            }
          end

          return {
            path_source,
            utils.source.fallback {
              sources.lsp,
              sources.treesitter,
            },
          }
        end,
      },
      sources = {
        -- Filter LSP to show only Class, Method, Function
        lsp = {
          valid_symbols = {
            'Class',
            'Method',
            'Function',
            'Interface',
            'Struct',
            'Constructor',
          },
        },
        -- Filter Treesitter to show only class, method, function
        treesitter = {
          valid_types = {
            'class',
            'method',
            'function',
            'interface',
            'struct',
            'constructor',
          },
        },
      },
      menu = {
        preview = true,
        quick_navigation = true,
        entry = {
          padding = {
            left = 1,
            right = 1,
          },
        },
      },
    },
  },
}
