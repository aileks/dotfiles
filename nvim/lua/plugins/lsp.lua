return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'b0o/schemastore.nvim',
    { 'nvimtools/none-ls.nvim', dependencies = 'nvim-lua/plenary.nvim' },
    'jay-babu/mason-null-ls.nvim',
    'MunifTanjim/prettier.nvim',
  },
  config = function()
    require('mason').setup({
      ui = {
        height = 0.8,
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        }
      },
    })

    require('mason-lspconfig').setup({
      ensure_installed = {
        "lua_ls",
        "solargraph",
        "rubocop",
        "pyright",
        "ruff",
        "ts_ls",
        "jsonls",
        "emmet_ls",
        "cssls",
        "tailwindcss",
      },
      automatic_installation = true
    })

    require('mason-null-ls').setup({
      ensure_installed = {
        "prettier",
        "prettierd",
        "black",
        "isort",
        "rubocop",
        "erb_lint",
      },
      automatic_installation = true
    })

    local lspconfig = require('lspconfig')
    local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
    capabilities.textDocument.completion.completionItem.snippetSupport = true

    -- Common on_attach function
    local on_attach = function(client, bufnr)
      vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

      -- Mappings (only set for current buffer)
      local bufopts = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
      vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
      vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
      vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
      vim.keymap.set('n', '<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, bufopts)
      vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
      vim.keymap.set('n', '<leader>lf', function() vim.lsp.buf.format { async = true } end, bufopts)
    end

    -- Lua
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            library = {
              [vim.fn.expand('$VIMRUNTIME/lua')] = true,
              [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
            },
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })

    -- Ruby
    lspconfig.solargraph.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        -- Disable formatting in favor of rubocop
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end,
      settings = {
        solargraph = {
          diagnostics = true,
          completion = true,
          hover = true,
          formatting = false,
          symbols = true,
          definitions = true,
          references = true,
          folding = true,
          highlights = true,
          autoformat = false,
          useBundler = true,
          bundlerPath = "bundle",
          transport = "stdio",
        },
      },
      init_options = {
        formatting = false,
      },
      cmd = { "solargraph", "stdio" },
      filetypes = { "ruby", "eruby" },
      root_dir = lspconfig.util.root_pattern("Gemfile", ".git"),
    })
    lspconfig.rubocop.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        client.server_capabilities.documentFormattingProvider = true
        client.server_capabilities.documentRangeFormattingProvider = true
      end,
      cmd = { "rubocop", "--lsp" },
    })

    -- Python
    lspconfig.pyright.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "python" },
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            autoImportCompletions = true,
          },
        },
      },
    })
    lspconfig.ruff.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
      end,
      init_options = {
        settings = {
          lineLength = 88,
          logLevel = "error",
          lint = {
            enable = true,
            select = { "E", "F", "N", "C4", "RUFF", "I" },
          },
          format = {
            enable = true,
          },
        }
      },
    })

    -- TypeScript/JavaScript
    lspconfig.ts_ls.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        -- Disable formatting in favor of prettier
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end,
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
      settings = {
        typescript = {
          preferences = {
            importModuleSpecifier = "relative"
          }
        },
        javascript = {
          preferences = {
            importModuleSpecifier = "relative"
          }
        }
      }
    })

    -- JSON
    lspconfig.jsonls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        json = {
          schemas = require('schemastore').json.schemas(),
          validate = { enable = true },
        },
      },
    })

    -- Emmet
    lspconfig.emmet_ls.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end,
      filetypes = {
        "css", "eruby", "html", "htmldjango", "javascriptreact",
        "less", "sass", "scss", "svelte", "pug", "typescriptreact", "vue"
      },
      init_options = {
        html = {
          options = {
            ["bem.enabled"] = true,
          },
        },
      }
    })

    -- CSS
    lspconfig.cssls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        css = {
          validate = true,
          lint = {
            unknownAtRules = "ignore"
          }
        },
        scss = {
          validate = true,
          lint = {
            unknownAtRules = "ignore"
          }
        },
        less = {
          validate = true,
          lint = {
            unknownAtRules = "ignore"
          }
        }
      }
    })

    -- Tailwind
    lspconfig.tailwindcss.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = {
        "css", "scss", "sass", "html", "htmldjango", "eruby",
        "javascript", "javascriptreact", "typescript", "typescriptreact",
        "vue", "svelte"
      },
      settings = {
        tailwindCSS = {
          experimental = {
            classRegex = {
              "class[:]\\s*?[\"'`]([^\"'`]*).*?[\"'`]",
              "[\"'`]([^\"'`]*)[\"'`]",
            },
          },
        },
      },
    })

    -- none-ls
    local null_ls = require('null-ls')
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

    null_ls.setup({
      temp_dir = '/tmp',
      sources = {
        -- JavaScript/TypeScript
        null_ls.builtins.formatting.prettierd.with({
          condition = function(utils)
            return utils.root_has_file({
              '.prettierrc', '.prettierrc.json', '.prettierrc.yml',
              '.prettierrc.yaml', '.prettierrc.js', 'prettier.config.js',
              '.prettierrc.cjs', 'prettier.config.cjs'
            })
          end,
        }),

        -- Python
        null_ls.builtins.formatting.black.with({
          extra_args = { "--fast", "--line-length", "88" }
        }),
        null_ls.builtins.formatting.isort.with({
          extra_args = { "--profile", "black" }
        }),

        -- Ruby (fallback)
        null_ls.builtins.formatting.rubocop.with({
          condition = function(utils)
            return utils.root_has_file({ '.rubocop.yml', '.rubocop.yaml' })
          end,
        }),

        -- ERB
        null_ls.builtins.diagnostics.erb_lint.with({
          condition = function(utils)
            return utils.root_has_file({ '.erb-lint.yml' })
          end,
        }),
      },
      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr = bufnr,
                timeout_ms = 5000,
                filter = function(client)
                  -- Only use null-ls for formatting
                  return client.name == "null-ls"
                end
              })
            end,
          })
        end
      end,
    })

    -- Prettier
    require('prettier').setup({
      bin = 'prettierd',
      cli_options = {
        arrow_parens = 'avoid',
        jsx_single_quote = true,
        print_width = 100,
        single_attribute_per_line = false,
        single_quote = true,
        tab_width = 2,
        trailing_comma = 'es5',
        use_tabs = false,
        vue_indent_script_and_style = true,
      },
      filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        'vue',
        'html',
        'css',
        'scss',
        'sass',
        'json',
        'yaml',
        'markdown',
        'graphql',
      },
    })

    -- Global LSP keymaps
    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', '<leader>d', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
    vim.keymap.set('n', '[d', function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set('n', ']d', function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set('n', '<leader>T', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

    -- Additional LSP keymaps
    vim.keymap.set('n', 'gi', ':Telescope lsp_implementations<CR>', { silent = true })
    vim.keymap.set('n', 'gr', ':Telescope lsp_references<CR>', { silent = true })
    vim.keymap.set('n', '<leader>lr', ':LspRestart<CR>', { silent = true })
    -- vim.keymap.set('n', '<leader>lf', ':Format<CR>', { silent = true })
    vim.keymap.set('n', '<leader>lp', ':Prettier<CR>', { silent = true })
    vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)

    -- Commands
    vim.api.nvim_create_user_command('Format', function()
      vim.lsp.buf.format({ timeout_ms = 5000 })
    end, {})

    -- Diagnostics
    vim.diagnostic.config({
      virtual_text = {
        enabled = true,
        source = "if_many",
        prefix = "●",
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        source = "always",
        border = "rounded",
        header = "",
        prefix = "",
      },
    })

    local signs = { Error = "", Warn = "", Hint = "", Info = "" }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    local border = {
      { "🭽", "FloatBorder" },
      { "▔", "FloatBorder" },
      { "🭾", "FloatBorder" },
      { "▕", "FloatBorder" },
      { "🭿", "FloatBorder" },
      { "▁", "FloatBorder" },
      { "🭼", "FloatBorder" },
      { "▏", "FloatBorder" },
    }

    local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
    function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
      opts = opts or {}
      opts.border = opts.border or border
      return orig_util_open_floating_preview(contents, syntax, opts, ...)
    end
  end,
}
