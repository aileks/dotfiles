local neotest = require('neotest')

neotest.setup({
  adapters = {
    require('neotest-go')({ experimental = { test_table = true } }),
  },
})

local map = vim.keymap.set

map('n', '<leader>tt', function()
  neotest.run.run()
end, { desc = 'Run nearest test' })
map('n', '<leader>tf', function()
  neotest.run.run(vim.fn.expand('%'))
end, { desc = 'Run file tests' })
map('n', '<leader>ta', function()
  neotest.run.run(vim.fn.getcwd())
end, { desc = 'Run all tests' })
map('n', '<leader>td', function()
  neotest.run.run({ strategy = 'dap' })
end, { desc = 'Debug nearest test' })
map('n', '<leader>ts', function()
  neotest.summary.toggle()
end, { desc = 'Test summary' })
map('n', '<leader>to', function()
  neotest.output.open({ enter = true })
end, { desc = 'Test output' })
