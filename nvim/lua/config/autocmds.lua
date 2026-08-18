vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

local indents = {
  go = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  python = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  sql = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  c = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
}

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local opts = indents[args.match]
    if not opts then
      return
    end
    vim.bo[args.buf].expandtab = args.match ~= 'go'
    for opt, value in pairs(opts) do
      vim.bo[args.buf][opt] = value
    end
  end,
})

vim.diagnostic.config({
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✘',
      [vim.diagnostic.severity.WARN] = '▲',
      [vim.diagnostic.severity.HINT] = '⚑',
      [vim.diagnostic.severity.INFO] = '',
    },
  },
})
