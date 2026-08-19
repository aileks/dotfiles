require('nvim-treesitter').install({
  'lua',
  'vim',
  'vimdoc',
  'query',
  'markdown',
  'markdown_inline',
  'python',
  'sql',
  'javascript',
  'typescript',
  'tsx',
  'json',
  'yaml',
  'html',
  'css',
  'bash',
  'diff',
  'gitcommit',
})

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
