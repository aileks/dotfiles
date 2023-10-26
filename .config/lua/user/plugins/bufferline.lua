require('bufferline').setup({
  options = {
    highlights = require('catppuccin.groups.integrations.bufferline').get(),
    hover = {
      enabled = true,
      delay = 150,
      reveal = {'close'},
    },
    show_close_icon = true,
    buffer_close_icon = '󰅖',
    close_icon = '',
    tab_size = 0,
    max_name_length = 25,
    offsets = {
      {
        filetype = 'neo-tree',
        text = 'Neotree',
        text_align = 'center',
      },
    },
    custom_areas = {
      left = function()
        return {
          { text = ' 󰄛  ', fg = '#ca9ee6' },
        }
      end,
    },
    separator_style = 'thin',
    modified_icon = '󰐙',
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
  },
})

vim.keymap.set('n', '<leader>bb', ':BufferLinePick<CR>')
vim.keymap.set('n', '<leader>bd', ':BufferLinePickClose<CR>')
vim.keymap.set('n', '<leader>bc', ':BufferLineCloseOthers<CR>')
