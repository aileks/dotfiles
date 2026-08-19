local dap = require('dap')
local dapui = require('dapui')

require('dap-python').setup('debugpy-adapter')

dap.adapters['pwa-node'] = {
  type = 'server',
  host = 'localhost',
  port = '${port}',
  executable = {
    command = 'js-debug-adapter',
    args = { '${port}' },
  },
}
for _, ft in ipairs({ 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' }) do
  dap.configurations[ft] = {
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch file',
      program = '${file}',
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
    },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach to process',
      processId = require('dap.utils').pick_process,
      cwd = vim.fn.getcwd(),
    },
  }
end

dapui.setup({})

dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticSignWarn' })

local map = vim.keymap.set

map('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle breakpoint' })
map('n', '<leader>dB', function()
  dap.set_breakpoint(nil, nil, vim.fn.input('Log: '))
end, { desc = 'Logpoint' })
map('n', '<leader>dc', dap.continue, { desc = 'Continue / start' })
map('n', '<leader>di', dap.step_into, { desc = 'Step into' })
map('n', '<leader>do', dap.step_over, { desc = 'Step over' })
map('n', '<leader>dO', dap.step_out, { desc = 'Step out' })
map('n', '<leader>dr', dap.repl.open, { desc = 'REPL' })
map('n', '<leader>du', dapui.toggle, { desc = 'Toggle DAP UI' })
map('n', '<leader>dx', dap.terminate, { desc = 'Terminate' })
