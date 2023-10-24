-- Lazy.nvim bootstrap
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins go here
require('lazy').setup({
    {
        'catppuccin/nvim',
        name = 'catppuccin',
        priority = 1000,
    },

    {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup({
                toggler = {
                    line = '<leader>/',
                },
                opleader = {
                    line = '<leader>/',
                }
            })
        end,
        lazy = false,
    },

    'tpope/vim-surround',

    'tpope/vim-eunuch',

    'tpope/vim-unimpaired',

    'tpope/vim-sleuth',

    'tpope/vim-repeat',

    'farmergreg/vim-lastplace',

    'nelstrom/vim-visual-star-search',

    'jessarcher/vim-heritage',

    {
        'whatyouhide/vim-textobj-xmlattr',
        dependencies = 'kana/vim-textobj-user',
    },

    {
        'windwp/nvim-autopairs',
        config = function()
            require('nvim-autopairs').setup()
        end,
    },

    'hiphish/rainbow-delimiters.nvim',

    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'JoosepAlviste/nvim-ts-context-commentstring',
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        config = function()
            require('user/plugins/treesitter')
        end,
    },

    {
        'AndrewRadev/splitjoin.vim',
        config = function()
            vim.g.splitjoin_html_attributes_bracket_on_new_line = 1
            vim.g.splitjoin_trailing_comma = 1
            vim.g.splitjoin_php_method_chain_full = 1
        end,
    },

    {
        'sickill/vim-pasta',
        config = function()
            vim.g.pasta_disabled_filetypes = { 'fugitive' }
        end,
    },

    {
        'max397574/better-escape.nvim',
        config = function()
            require('better_escape').setup()
        end,
    },

    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-tree/nvim-web-devicons', opts = true },
            'sharkdp/fd',
            'nvim-telescope/telescope-live-grep-args.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        },
        config = function()
            require('user/plugins/telescope')
        end,
    },

    {
        'nvim-neo-tree/neo-tree.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
            { 'nvim-tree/nvim-web-devicons', opts = true },
            {
                's1n7ax/nvim-window-picker',
                config = function()
                    require 'window-picker'.setup({
                        filter_rules = {
                            include_current_win = false,
                            autoselect_one = true,
                            bo = {
                                filetype = { 'neo-tree', "neo-tree-popup", "notify" },
                                buftype = { 'terminal', "quickfix" },
                            },
                        },
                    })
                end,
            },
        },
        config = function()
            vim.fn.sign_define("DiagnosticSignError",
              {text = " ", texthl = "DiagnosticSignError"})
            vim.fn.sign_define("DiagnosticSignWarn",
              {text = " ", texthl = "DiagnosticSignWarn"})
            vim.fn.sign_define("DiagnosticSignInfo",
              {text = " ", texthl = "DiagnosticSignInfo"})
            vim.fn.sign_define("DiagnosticSignHint",
              {text = "󰌵", texthl = "DiagnosticSignHint"})
            require('user/plugins/neo-tree')
        end,
    },

    {
        'nvim-lualine/lualine.nvim',
        dependencies = {
            { 'nvim-tree/nvim-web-devicons', opts = true },
        },
        config = function()
            require('user/plugins/lualine')
        end,
    },

    {
        'akinsho/bufferline.nvim',
        event = 'VeryLazy',
        dependencies = 'catppuccin',
        config = function()
            require('user/plugins/bufferline')
        end,
    },

    {
        'andweeb/presence.nvim',
        lazy = false,
        config = function()
            require('presence').setup({
                auto_update = true,
                neovim_image_text = 'Problem, liberal?',
                main_image = 'neovim',
                enable_line_number = true,
                buttons = true,
                show_time = true,
                editing_text = "It's  probably PHP...",
                workspace_text = "I am sworn to secrecy.",
            })
        end,
    },

    {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            require('ibl').setup()
        end,
    },

    {
        'goolord/alpha-nvim',
        config = function()
            require('user/plugins/alpha')
        end,
    },

    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup({ current_line_blame = true })
            vim.keymap.set('n', ']h', ':Gitsigns next_hunk<CR>')
            vim.keymap.set('n', '[h', ':Gitsigns prev_hunk<CR>')
            vim.keymap.set('n', 'gs', ':Gitsigns stage_hunk<CR>')
            vim.keymap.set('n', 'gu', ':Gitsigns undo_stage_hunk<CR>')
            vim.keymap.set('n', 'gp', ':Gitsigns preview_hunk<CR>')
            vim.keymap.set('n', 'gp', ':Gitsigns blame_line<CR>')
        end,
    },

    {
        'tpope/vim-fugitive',
        dependencies = 'tpope/vim-rhubarb',
    },

    {
        'akinsho/toggleterm.nvim',
        cmd = { 'ToggleTerm', 'TermExec' },
        opts = {
            highlights = {
              Normal = { link = 'Normal' },
              NormalNC = { link = 'NormalNC' },
              NormalFloat = { link = 'NormalFloat' },
              FloatBorder = { link = 'FloatBorder' },
              StatusLine = { link = 'StatusLine' },
              StatusLineNC = { link = 'StatusLineNC' },
              WinBar = { link = 'WinBar' },
              WinBarNC = { link = 'WinBarNC' },
            },
            size = 10,
            on_create = function()
                vim.opt.foldcolumn = '0'
                vim.opt.signcolumn = 'no'
            end,
            open_mapping = [[<F7>]],
            shading_factor = 2,
            direction = 'float',
            float_opts = { border = 'rounded' },
        },
        lazy = false,
    },

    -- LSP with config in external file
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'b0o/schemastore.nvim',
            'nvimtools/none-ls.nvim',
            'jay-babu/mason-null-ls.nvim'
        },
        config = function()
            require('user/plugins/lspconfig')
        end,
    },

    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lsp-signature-help',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            'onsails/lspkind-nvim',
        },
        config = function()
            require('user/plugins/cmp')
        end,
    },

    {
        'phpactor/phpactor',
        event = 'VeryLazy',
        filetype = 'php',
        run = 'composer install --no-dev --optimize-autoloader', -- Run manually if it doesn't work
        config = function()
            vim.keymap.set('n', '<Leader>pm', ':PhpactorContextMenu<CR>')
            vim.keymap.set('n', '<Leader>pn', ':PhpactorClassNew<CR>')
        end,
    },

    {
        'tpope/vim-projectionist',
        dependencies = 'tpope/vim-dispatch',
        config = function()
            require('user/plugins/projectionist')
        end,
    },

    {
        'vim-test/vim-test',
        config = function()
            require('user/plugins/vim-test')
        end,
    },
})
