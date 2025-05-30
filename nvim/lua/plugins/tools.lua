return {
  -- Lazygit integration
  {
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>lg", "<CMD>LazyGit<CR>", desc = "LazyGit" },
    },
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    lazy = false,
    keys = {
      { "<leader>e", "<CMD>Oil<CR>", desc = "Open parent directory" }
    }
  }
}
