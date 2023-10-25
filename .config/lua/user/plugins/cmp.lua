local cmp = require('cmp')
local luasnip = require('luasnip')
local lspkind = require('lspkind')

require('luasnip/loaders/from_snipmate').lazy_load()

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line, true)[1]:sub(col, col):match('%s') == nil
end,

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  formatting = {
    format = lspkind.cmp_format(),
  },
  mapping = {
    ['<C-n'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  },
  experimental = {
    ghost_text = true,
  },
})
