require('mason').setup()
require('mason-lspconfig').setup({ automatic_installation = true })

-- Capabilities for LSPs
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- PHP
require('lspconfig').intelephense.setup({
  capabilities = capabilities,
  filetypes = {
    "php",
    "php.html",
    "phtml",
  },
})

-- JavaScript, Vue, and TypeScript
require('lspconfig').volar.setup({
    capabilities = capabilities,
    filetypes = {
    'typescript',
    'javascript',
    'javascriptreact',
    'typescriptreact',
    'vue',
  },
})

-- Tailwind CSS
require('lspconfig').tailwindcss.setup({ capabilities = capabilities })

-- Emmet
require('lspconfig').emmet_ls.setup({
  capabilities = capabilities,
  filetypes = {
    'html',
    'css',
    'php',
    'javascriptreact',
    'typescriptreact',
    'vue',
    'php.html',
    'phtml',
  },
})

-- JSON
require('lspconfig').jsonls.setup({
    capabilities = capabilities,
    settings = {
        json = {
            schemas = require('schemastore').json.schemas(),
        },
    },
})

-- HTML
require('lspconfig').html.setup({
  capabilities = capabilities,
  filetypes = {
    'html',
    'php',
    'php.html',
    'phtml',
    'javascriptreact',
    'typescriptreact',
    'vue',
  },
})

-- Null-ls/None-ls
require('null-ls').setup({
  sources = {
    require('null-ls').builtins.diagnostics.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ '.eslintrc.js' })
      end,
    }),
    require('null-ls').builtins.diagnostics.trail_space.with({ disabled_filetypes = { 'neo-tree' } }),
    require('null-ls').builtins.formatting.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file({ '.eslintrc.js' })
      end,
    }),
    require('null-ls').builtins.formatting.prettierd,
  },
})
require('mason-null-ls').setup({ automatic_installation = true })

-- Keybinds
vim.keymap.set('n', '<Leader>lf', '<cmd>lua vim.lsp.buf.format()<CR>')
vim.keymap.set('n', '<Leader>d', '<cmd>lua vim.diagnostic.open_float()<CR>')
vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', 'gi', ':Telescope lsp_implementations<CR>')
vim.keymap.set('n', 'gr', ':Telescope lsp_references<CR>')
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')

-- Diagnostics
vim.diagnostic.config({
    virtual_text = false,
    float = {
        source = true,
    },
})
vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })
