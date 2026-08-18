vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(),
})

vim.lsp.config('gopls', {
  settings = {
    gopls = {
      gofumpt = true,
      analyses = { shadow = true, unusedparams = true },
      staticcheck = true,
    },
  },
})

vim.lsp.config('basedpyright', {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = 'standard',
        organizeImports = false,
      },
    },
  },
})

vim.lsp.config('ruff', {
  init_options = { settings = { args = {} } },
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false },
      diagnostics = { globals = { 'vim' } },
    },
  },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc })
    end
    map('gd', vim.lsp.buf.definition, 'Go to definition')
    map('gD', vim.lsp.buf.declaration, 'Go to declaration')
    map('grr', vim.lsp.buf.references, 'References')
    map('gy', vim.lsp.buf.type_definition, 'Go to type definition')
    map('K', vim.lsp.buf.hover, 'Hover')
    map('<C-k>', vim.lsp.buf.signature_help, 'Signature help')
    map('<leader>la', vim.lsp.buf.code_action, 'Code action')
    map('<leader>lr', vim.lsp.buf.rename, 'Rename')
    map('<leader>ls', '<cmd>FzfLua lsp_document_symbols<CR>', 'Document symbols')
    map('<leader>wS', '<cmd>FzfLua lsp_workspace_symbols<CR>', 'Workspace symbols')
  end,
})
