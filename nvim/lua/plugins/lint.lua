require('lint').linters_by_ft = {
  sql = { 'sqlfluff' },
  javascript = { 'eslint_d' },
  javascriptreact = { 'eslint_d' },
  typescript = { 'eslint_d' },
  typescriptreact = { 'eslint_d' },
}

vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost' }, {
  callback = function()
    require('lint').try_lint()
  end,
})

vim.keymap.set('n', '<leader>ln', function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<leader>lp', function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = 'Previous diagnostic' })
