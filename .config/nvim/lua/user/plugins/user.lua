return {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },

  {
    "andweeb/presence.nvim",
    lazy = false,
    config = function()
      require("presence").setup {
        auto_update = true,
        neovim_image_text = "Problem, liberal?",
        main_image = "neovim",
        enable_line_number = false,
        buttons = true,
        show_time = true,
        workspace_text = "I am sworn to secrecy",
        editing_text = "It's probably PHP...",
      }
    end,
  },

  {
    "Exafunction/codeium.vim",
    event = "BufEnter",
    config = function()
      vim.keymap.set("i", "<C-]>", function() return vim.fn["codeium#Accept"]() end, { expr = true })
      vim.keymap.set("i", "<C-x>", function() return vim.fn["codeium#Clear"]() end, { expr = true })
    end,
  },
}
