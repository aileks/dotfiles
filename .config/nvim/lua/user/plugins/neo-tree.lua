require('neo-tree').setup({
    sources = { 'filesystem', 'buffers', 'git_status' },
    source_selector = {
        winbar = true,
        content_layout = 'center',
    },

    close_if_last_window = false,
    enable_git_status = true,
    enable_diagnostics = true,
    enable_normal_mode_for_inputs = false,
    open_files_do_not_replace_types = { 'terminal', 'trouble', 'qf' },
    sort_case_insensitive = false,
    sort_function = nil,

    default_component_configs = {
        container = {
            enable_character_fade = true
        },
        indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            indent_marker = '│',
            last_indent_marker = '└',
            highlight = 'NeoTreeIndentMarker',
            with_expanders = nil,
            expander_collapsed = '',
            expander_expanded = '',
            expander_highlight = 'NeoTreeExpander',
        },
        icon = {
            folder_closed = '',
            folder_open = '',
            folder_empty = '󰜌',
            default = '*',
            highlight = 'NeoTreeFileIcon'
        },
        modified = {
            symbol = '[+]',
            highlight = 'NeoTreeModified',
        },
        name = {
            trailing_slash = false,
            use_git_status_colors = true,
            highlight = 'NeoTreeFileName',
        },
        git_status = {
            symbols = {
                added     = '',
                modified  = '',
                deleted   = '✖',
                renamed   = '󰁕',
                untracked = '',
                ignored   = '',
                unstaged  = '󰄱',
                staged    = '',
                conflict  = '',
            }
        },
        file_size = {
            enabled = true,
            required_width = 64,
        },
        type = {
            enabled = true,
            required_width = 122,
        },
        last_modified = {
            enabled = true,
            required_width = 88,
        },
        created = {
            enabled = true,
            required_width = 110,
        },
        symlink_target = {
            enabled = false,
        },
    },
    window = {
        position = 'left',
        width = 27,
        mapping_options = {
            noremap = true,
            nowait = true,
        },
        mappings = {
            ['<space>'] = {
                'toggle_node',
                nowait = false,
            },
            ['<2-LeftMouse>'] = 'open',
            ['<CR>'] = 'open',
            ['l'] = 'open',
            ['<Esc>'] = 'cancel',
            ['P'] = { 'toggle_preview', config = { use_float = true } },
            ['L'] = 'focus_preview',
            ['S'] = 'open_split',
            ['s'] = 'open_vsplit',
            ['t'] = 'open_tabnew',
            ['w'] = 'open_with_window_picker',
            ['h'] = 'close_node',
            ['z'] = 'close_all_nodes',
            ['a'] = {
                'add',
                config = {
                    show_path = 'none'
                }
            },
            ['A'] = 'add_directory',
            ['d'] = 'delete',
            ['r'] = 'rename',
            ['y'] = 'copy_to_clipboard',
            ['x'] = 'cut_to_clipboard',
            ['p'] = 'paste_from_clipboard',
            ['c'] = 'copy',
            ['m'] = 'move',
            ['q'] = 'close_window',
            ['R'] = 'refresh',
            ['?'] = 'show_help',
            ['<'] = 'prev_source',
            ['>'] = 'next_source',
            ['i'] = 'show_file_details',
        }
    },
    nesting_rules = {},
    filesystem = {
        filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = true,
            hide_hidden = true,
        },
        follow_current_file = {
            enabled = true,
            leave_dirs_open = true,
        },
        group_empty_dirs = true,
        hijack_netrw_behavior = 'open_default',
        use_libuv_file_watcher = false,
        window = {
            mappings = {
                ['<BS>'] = 'navigate_up',
                ['.'] = 'set_root',
                ['H'] = 'toggle_hidden',
                ['/'] = 'fuzzy_finder',
                ['D'] = 'fuzzy_finder_directory',
                ['#'] = 'fuzzy_sorter',
                ['f'] = 'filter_on_submit',
                ['<C-x>'] = 'clear_filter',
                ['[g'] = 'prev_git_modified',
                [']g'] = 'next_git_modified',
                ['o'] = { 'show_help', nowait=false, config = { title = 'Order by', prefix_key = 'o' }},
                ['oc'] = { 'order_by_created', nowait = false },
                ['od'] = { 'order_by_diagnostics', nowait = false },
                ['og'] = { 'order_by_git_status', nowait = false },
                ['om'] = { 'order_by_modified', nowait = false },
                ['on'] = { 'order_by_name', nowait = false },
                ['os'] = { 'order_by_size', nowait = false },
                ['ot'] = { 'order_by_type', nowait = false },
            },
            fuzzy_finder_mappings = {
                ['<down>'] = 'move_cursor_down',
                ['<C-n>'] = 'move_cursor_down',
                ['<up>'] = 'move_cursor_up',
                ['<C-p>'] = 'move_cursor_up',
            },
        },

    },
    buffers = {
        follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
        },
        group_empty_dirs = true,
        show_unloaded = true,
        window = {
            mappings = {
                ['bd'] = 'buffer_delete',
                ['<BS>'] = 'navigate_up',
                ['.'] = 'set_root',
                ['o'] = { 'show_help', nowait=false, config = { title = 'Order by', prefix_key = 'o' }},
                ['oc'] = { 'order_by_created', nowait = false },
                ['od'] = { 'order_by_diagnostics', nowait = false },
                ['om'] = { 'order_by_modified', nowait = false },
                ['on'] = { 'order_by_name', nowait = false },
                ['os'] = { 'order_by_size', nowait = false },
                ['ot'] = { 'order_by_type', nowait = false },
            }
        },
    },
    git_status = {
        window = {
            position = 'float',
            mappings = {
                ['A']  = 'git_add_all',
                ['gu'] = 'git_unstage_file',
                ['ga'] = 'git_add_file',
                ['gr'] = 'git_revert_file',
                ['gc'] = 'git_commit',
                ['gp'] = 'git_push',
                ['gg'] = 'git_commit_and_push',
                ['o'] = { 'show_help', nowait=false, config = { title = 'Order by', prefix_key = 'o' }},
                ['oc'] = { 'order_by_created', nowait = false },
                ['od'] = { 'order_by_diagnostics', nowait = false },
                ['om'] = { 'order_by_modified', nowait = false },
                ['on'] = { 'order_by_name', nowait = false },
                ['os'] = { 'order_by_size', nowait = false },
                ['ot'] = { 'order_by_type', nowait = false },
            }
        }
    }
})

vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>')
vim.keymap.set('n', '<leader>o', '<C-w><C-w>')
