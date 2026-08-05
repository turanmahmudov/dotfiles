local M = {}

local ORGANIZE_IMPORTS = 'source.organizeImports'

-- Code action kinds are hierarchical, so a server may advertise a sub-kind such
-- as `source.organizeImports.ts` instead of the bare kind. Ask for exactly what
-- the server offers, otherwise it may not recognise the request.
local function resolveOrganizeKinds(client)
  local provider = client.server_capabilities.codeActionProvider
  local advertised = type(provider) == 'table' and provider.codeActionKinds or nil
  if not advertised then
    return {}
  end

  local kinds = {}
  for _, kind in ipairs(advertised) do
    if kind == ORGANIZE_IMPORTS or vim.startswith(kind, ORGANIZE_IMPORTS .. '.') then
      table.insert(kinds, kind)
    end
  end

  return kinds
end

local function applyCodeAction(client, action, bufnr)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end

  if action.command then
    local command = type(action.command) == 'table' and action.command or action
    client:exec_cmd(command, { bufnr = bufnr })
  end
end

function M.organizeImports(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    local kinds = resolveOrganizeKinds(client)

    if #kinds > 0 then
      local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
      params.context = { only = kinds, diagnostics = {} }

      local responses = client:request_sync('textDocument/codeAction', params, 1000, bufnr)
      for _, action in ipairs(responses and responses.result or {}) do
        applyCodeAction(client, action, bufnr)
      end
    end
  end
end

return M
