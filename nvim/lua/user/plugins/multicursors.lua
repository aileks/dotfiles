return {
  "smoka7/multicursors.nvim",
  event = "VeryLazy",
  dependencies = { 'nvimtools/hydra.nvim' },
  cmd = { 'MCstart', 'MCvisual', 'MCclear', 'MCpattern', 'MCvisualPattern', 'MCunderCursor' },
  keys = {
    {
      mode = { 'v', 'n' },
      '<Leader>m',
      '<cmd>MCstart<cr>',
    },
  },
  config = function()
    require('multicursors').setup({
      ['<C-/>'] = {
        method = function()
          require('multicursors.utils').call_on_selections(function(selection)
            vim.api.nvim_win_set_cursor(0, { selection.row + 1, selection.col + 1 })
            local line_count = selection.end_row - selection.row + 1
            vim.cmd('normal ' .. line_count .. 'gcc')
          end)
        end,
      },
    })
  end
}
