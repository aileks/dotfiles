local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
local highlight_group = augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- Format on save
local format_group = augroup("FormatOnSave", { clear = true })
autocmd("BufWritePre", {
  callback = function(args)
    local conform = require("conform")
    if conform then
      conform.format({ bufnr = args.buf })
    end
  end,
  group = format_group,
  pattern = "*",
})
