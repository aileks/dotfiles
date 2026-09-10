require('nvim-autopairs').setup({})

require('blink.cmp').setup({
  keymap = { preset = 'super-tab' },
  appearance = { nerd_font_variant = 'normal' },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  snippets = { preset = 'default' },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  signature = { enabled = true },
})
