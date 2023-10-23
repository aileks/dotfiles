require('bufferline').setup({
  options = {
    hover = {
      enabled = true,
      delay = 150,
      reveal = {'close'},
    },
    indicator = {
      icon = '  ',
    },
    show_close_icon = true,
    buffer_close_icon = '󰅖',
    close_icon = '',
    tab_size = 0,
    max_name_length = 25,
    offsets = {
      {
        filetype = 'neo-tree',
        text = '  Files',
        text_align = 'left',
      },
    },
    separator_style = 'thin',
    modified_icon = '󰐙',
    highlights = require('catppuccin.groups.integrations.bufferline').get(),
    always_show_bufferline = false,
    diagnostics_indicator = function(count, level, diagnostics_dict, context)
      local s = " "
      for e, n in pairs(diagnostics_dict) do
        local sym = e == "error" and " "
        or (e == "warning" and " " or "" )
        s = s .. n .. sym
      end
      return s
    end,
    custom_areas = {
      left = function() return {
        { text = '  ', fg = '#a6d189' },
      }
      end,
    },
  },
})

vim.keymap.set('n', '<leader>bb', ':BufferLinePick<CR>')
vim.keymap.set('n', '<leader>bd', ':BufferLinePickClose<CR>')
vim.keymap.set('n', '<leader>bl', ':BufferLineCycleNext<CR>')
vim.keymap.set('n', '<leader>bh', ':BufferLineCyclePrev<CR>')
vim.keymap.set('n', '<leader>bc', ':BufferLineCloseOthers<CR>')
