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
            config = function()
	        vim.cmd([[colorscheme catppuccin-frappe]])
            end,
            lazy = false,
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

    {
        'nvim-treesitter/nvim-treesitter',
            config = function()
                require('nvim-treesitter').setup()
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
                require("better_escape").setup()
            end,
    },


    {
        'nvim-telescope/telescope.nvim',
            dependencies = {
                'nvim-lua/plenary.nvim',
                { 'nvim-tree/nvim-web-devicons', opt = true },
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
                { 'nvim-tree/nvim-web-devicons', opt = true },
                { 's1n7ax/nvim-window-picker',
                    config = function()
                        require('window-picker').setup({
                            filter_rules = {
                                include_current_win = false,
                                autoselect_one = true,
                                bo = {
                                    filetype = { 'neo-tree', 'neo-tree-pupup', 'notify' },
                                    buftype = { 'terminal', 'quickfix' },
                                },
                            },
                        })
                    end,
                },
            },
            config = function()
                require('user/plugins/neo-tree')
            end,
    },

    {
        'nvim-lualine/lualine.nvim',
            dependencies = {
                { 'nvim-tree/nvim-web-devicons', opt = true },
            },
            config = function()
                require('user/plugins/lualine')
            end,
    },

    { 
        'akinsho/bufferline.nvim',
            dependencies = {
                'catppuccin',
                { 'nvim-tree/nvim-web-devicons', opt = true },
            },
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
                    workspace_text = "I am sworn to secrecy.",
                    editing_text = "It's probably PHP...",
                })
            end,
    },

    {
        'lukas-reineke/indent-blankline.nvim',
            config = function()
                require('ibl').setup()
            end,
    },

    'HiPhish/rainbow-delimiters.nvim',

    {
        'goolord/alpha-nvim',
            config = function()
                require('user/plugins/alpha')
            end,
    },

    {
        'lewis6991/gitsigns.nvim',
            config = function()
                require('gitsigns').setup()
                vim.keymap.set('n', ']h', ':Gitsigns next_hunk<CR>')
                vim.keymap.set('n', '[h', ':Gitsigns prev_hunk<CR>')
                vim.keymap.set('n', 'gs', ':Gitsigns stage_hunk<CR>')
                vim.keymap.set('n', 'gS', ':Gitsigns undo_stage_hunk<CR>')
                vim.keymap.set('n', 'gp', ':Gitsigns preview_hunk<CR>')
                vim.keymap.set('n', 'gp', ':Gitsigns blame_line<CR>')
            end,
            lazy = false,
    },
})
