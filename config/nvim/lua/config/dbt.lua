local M = {}

function M.find_root(path)
  local start = path
  if not start or start == '' then
    start = vim.uv.cwd()
  end
  return vim.fs.root(start, 'dbt_project.yml')
end

function M.setup()
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    group = vim.api.nvim_create_augroup('config-dbt', { clear = true }),
    desc = 'Use the dbt filetype inside dbt projects',
    pattern = '*.sql',
    callback = function(args)
      if not M.find_root(args.file) then
        return
      end
      pcall(vim.treesitter.stop, args.buf)
      vim.bo[args.buf].filetype = 'dbt'
    end,
  })
end

return M
