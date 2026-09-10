local plugins = {
  { src = 'https://github.com/aileks/cinder-grove.nvim.git' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
  { src = 'https://github.com/OXY2DEV/markview.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/goolord/alpha-nvim' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/folke/todo-comments.nvim' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/b0o/SchemaStore.nvim' },
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/mason-org/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/Saghen/blink.cmp', version = 'v1' },
  { src = 'https://github.com/rafamadriz/friendly-snippets' },
  { src = 'https://github.com/windwp/nvim-autopairs' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/nvim-mini/mini.surround' },
  { src = 'https://github.com/ibhagwan/fzf-lua' },
  { src = 'https://github.com/folke/which-key.nvim' },
  { src = 'https://github.com/folke/trouble.nvim' },
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/stevearc/aerial.nvim' },
  { src = 'https://github.com/Bekaboo/dropbar.nvim' },
  { src = 'https://github.com/folke/persistence.nvim' },
  { src = 'https://github.com/DNLHC/glance.nvim' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/mfussenegger/nvim-lint' },
  { src = 'https://github.com/stevearc/overseer.nvim' },
  { src = 'https://github.com/mfussenegger/nvim-dap' },
  { src = 'https://github.com/rcarriga/nvim-dap-ui' },
  { src = 'https://github.com/nvim-neotest/nvim-nio' },
  { src = 'https://github.com/mfussenegger/nvim-dap-python' },
  { src = 'https://github.com/theHamsta/nvim-dap-virtual-text' },
  { src = 'https://github.com/nvim-neotest/neotest' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-neotest/neotest-python' },
  { src = 'https://github.com/marilari88/neotest-vitest' },
  { src = 'https://github.com/thenbe/neotest-playwright' },
  { src = 'https://github.com/lewis6991/async.nvim' },
  { src = 'https://github.com/ThePrimeagen/refactoring.nvim' },
  { src = 'https://github.com/tpope/vim-dadbod' },
  { src = 'https://github.com/kristijanhusak/vim-dadbod-ui' },
  { src = 'https://github.com/kristijanhusak/vim-dadbod-completion' },
  { src = 'https://github.com/hat0uma/csvview.nvim' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
  { src = 'https://github.com/folke/noice.nvim' },
}

vim.pack.add(plugins)

vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Update all plugins' })

require('plugins.colors')
require('plugins.dashboard')
require('plugins.whichkey')
require('plugins.treesitter')
require('plugins.todo')
require('plugins.completion')
require('plugins.lsp')
require('plugins.mason')
require('plugins.fzf')
require('plugins.oil')
require('plugins.aerial')
require('plugins.dropbar')
require('plugins.glance')
require('plugins.git')
require('plugins.formatting')
require('plugins.lint')
require('plugins.overseer')
require('plugins.trouble')
require('plugins.dap')
require('plugins.neotest')
require('plugins.refactoring')
require('plugins.persistence')
require('plugins.sql')
require('plugins.csvview')
require('plugins.noice')
require('mini.surround').setup()
