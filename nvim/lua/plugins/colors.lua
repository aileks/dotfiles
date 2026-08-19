require('cinder-grove').setup({ transparent = true })
vim.cmd.colorscheme('cinder-grove')

require('lualine').setup({
  options = {
    theme = 'auto',
    icons_enabled = true,
    component_separators = '|',
    section_separators = '',
  },
})

require('ibl').setup()

require('markdown-plus').setup()
