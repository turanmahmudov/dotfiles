local M = {}

local function hasLspFolding(bufnr)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange) then
      return true
    end
  end

  return false
end

local function resolveFoldProvider(bufnr)
  local cached = vim.b[bufnr].fold_provider
  if cached then
    return cached
  end

  local provider = 'none'
  if hasLspFolding(bufnr) then
    provider = 'lsp'
  elseif pcall(vim.treesitter.get_parser, bufnr) then
    provider = 'treesitter'
  end

  vim.b[bufnr].fold_provider = provider

  return provider
end

function M.calculateFoldExpr()
  local provider = resolveFoldProvider(vim.api.nvim_get_current_buf())

  if provider == 'lsp' then
    return vim.lsp.foldexpr()
  end

  if provider == 'treesitter' then
    return vim.treesitter.foldexpr()
  end

  return '0'
end

return M
