return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
      })
    end,
  },
  {
    "ldelossa/vague.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("vague").setup({
        transparent = true
      })
      vim.cmd("colorscheme vague")
    end,
  },
  {
    "datsfilipe/min-theme.nvim",
    priority = 999,
    config = function()
      local ok, _ = pcall(vim.cmd, "colorscheme vague")
      if not ok then
        require("min-theme").setup({
          theme = "dark",
          transparent = true,
          italics = {
            comments = true,
            keywords = true,
            functions = true,
            strings = true,
            variables = true,
          },
          overrides = {},
        })
        vim.cmd("colorscheme min-theme")
      end
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      require("which-key").setup({})
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("ibl").setup({
        indent = { char = "│" },
        scope = { enabled = false },
      })
    end,
  },
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        "                                                     ",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
        "                                                     ",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", "󰈞  Find file", ":Telescope find_files <CR>"),
        dashboard.button("n", "󰈔  New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("r", "󰄉  Recent files", ":Telescope oldfiles <CR>"),
        dashboard.button("g", "󰊢  Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", "󰗼  Config", ":e $MYVIMRC <CR>"),
        dashboard.button("q", "󰗼  Quit", ":qa<CR>"),
      }
      local footer = function()
        local datetime = os.date("  %d-%m-%Y %H:%M:%S")
        local version = vim.version()
        local nvim_version = "  v" .. version.major .. "." .. version.minor .. "." .. version.patch
        return datetime .. " · " .. nvim_version
      end
      dashboard.section.footer.val = footer()
      require("alpha").setup(dashboard.config)
    end,
  },
  {
    "weilbith/nvim-code-action-menu",
    cmd = "CodeActionMenu",
    config = function()
      vim.g.code_action_menu_window_border = "single"
      vim.keymap.set("n", "<leader>ca", function()
        vim.cmd("CodeActionMenu")
      end, { desc = "Code Action Menu" })
    end,
  },
}
