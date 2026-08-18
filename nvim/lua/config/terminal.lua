local buf, win

local function float_term(cmd)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    return
  end
  buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = 'rounded',
  })
  if cmd then
    vim.fn.termopen(cmd)
  else
    vim.fn.termopen(vim.o.shell)
  end
  vim.cmd.startinsert()
end

vim.keymap.set('n', '<C-/>', function()
  float_term()
end, { desc = 'Toggle floating terminal' })
vim.keymap.set('t', '<C-/>', [[<C-\><C-n>]], { desc = 'Exit terminal insert mode' })

return { float_term = float_term }
