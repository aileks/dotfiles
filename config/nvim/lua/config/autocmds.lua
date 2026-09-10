local group = vim.api.nvim_create_augroup('config-general', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  desc = 'Highlight yanked text',
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

local indents = {
  go = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  python = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  sql = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  dbt = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  c = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  cpp = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
  zig = { tabstop = 4, shiftwidth = 4, softtabstop = 4 },
}

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  desc = 'Set language-specific indentation',
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
  virtual_text = false,
  virtual_lines = {
    current_line = true,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '✘',
      [vim.diagnostic.severity.WARN] = '▲',
      [vim.diagnostic.severity.HINT] = '⚑',
      [vim.diagnostic.severity.INFO] = '',
    },
  },
})
