local conform = require('conform')

conform.setup({
  formatters_by_ft = {
    python = { 'ruff_organize_imports', 'ruff_format' },
    go = { 'goimports', 'gofumpt' },
    c = { 'clang_format' },
    cpp = { 'clang_format' },
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    json = { 'prettier' },
    yaml = { 'prettier' },
    html = { 'prettier' },
    css = { 'prettier' },
    markdown = { 'prettier' },
    sql = { 'sqlfluff' },
    sh = { 'shfmt' },
    lua = { 'stylua' },
    bash = { 'shfmt' },
    zig = { 'zigfmt' },
  },

  formatters = {
    shfmt = {
      append_args = {
        '-i',
        '2',
        '-ci',
        '-bn',
      },
    },
    clang_format = {
      append_args = function(_, ctx)
        local config = vim.fs.find({ '.clang-format', '_clang-format' }, {
          path = vim.fs.dirname(ctx.filename),
          upward = true,
        })[1]

        if config then
          return {}
        end

        return {
          '--style=file:~/.clang-format',
        }
      end,
    },
  },

  format_on_save = {
    timeout_ms = 3000,
    lsp_format = 'fallback',
  },
})

vim.keymap.set('n', '<leader>lf', function()
  conform.format({
    async = true,
    lsp_format = 'fallback',
  })
end, { desc = 'Format buffer' })
