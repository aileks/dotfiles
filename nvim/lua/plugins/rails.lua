return {
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    dependencies = {
      "tpope/vim-bundler",
      "tpope/vim-rake",
      "tpope/vim-projectionist",
    },
    config = function()
      -- Rails.vim automatically detects Rails projects and provides commands like:
      -- :Econtroller, :Emodel, :Eview, :Eskip, :Eintegration
      -- :A to alternate between implementation and test
      -- :R to related files
      -- gf to go to file under cursor (enhanced for Rails)

      vim.g.rails_menu = 2
      vim.g.rails_mappings = 1
      vim.g.rails_modelines = 0

      -- Keymaps
      local keymap = vim.keymap

      -- Model/View/Controller navigation
      keymap.set("n", "<leader>rm", ":Emodel<CR>", { desc = "Rails: Go to Model" })
      keymap.set("n", "<leader>rv", ":Eview<CR>", { desc = "Rails: Go to View" })
      keymap.set("n", "<leader>rc", ":Econtroller<CR>", { desc = "Rails: Go to Controller" })
      keymap.set("n", "<leader>rh", ":Ehelper<CR>", { desc = "Rails: Go to Helper" })
      keymap.set("n", "<leader>rs", ":Eskip<CR>", { desc = "Rails: Go to Spec/Test" })
      keymap.set("n", "<leader>rf", ":Efixture<CR>", { desc = "Rails: Go to Fixture" })
      keymap.set("n", "<leader>ri", ":Einitializer<CR>", { desc = "Rails: Go to Initializer" })
      keymap.set("n", "<leader>rl", ":Elib<CR>", { desc = "Rails: Go to Lib" })
      keymap.set("n", "<leader>rt", ":Etask<CR>", { desc = "Rails: Go to Rake Task" })

      -- Rails commands
      keymap.set("n", "<leader>rr", ":Rails<CR>", { desc = "Rails: Run Rails Command" })
      keymap.set("n", "<leader>rg", ":Generate<CR>", { desc = "Rails: Generate" })
      keymap.set("n", "<leader>rd", ":Destroy<CR>", { desc = "Rails: Destroy" })

      -- Server and console
      keymap.set("n", "<leader>rS", ":Rails server<CR>", { desc = "Rails: Start Server" })
      keymap.set("n", "<leader>rC", ":Rails console<CR>", { desc = "Rails: Console" })

      -- Database
      keymap.set("n", "<leader>rdb", ":Rails dbconsole<CR>", { desc = "Rails: DB Console" })
      keymap.set("n", "<leader>rdm", ":Rails db:migrate<CR>", { desc = "Rails: DB Migrate" })
      keymap.set("n", "<leader>rdr", ":Rails db:rollback<CR>", { desc = "Rails: DB Rollback" })

      -- Testing shortcuts
      keymap.set("n", "<leader>rta", ":Rails test<CR>", { desc = "Rails: Run All Tests" })
      keymap.set("n", "<leader>rtf", function()
        local file = vim.fn.expand("%")
        vim.cmd("Rails test " .. file)
      end, { desc = "Rails: Test Current File" })
      keymap.set("n", "<leader>rtl", function()
        local file = vim.fn.expand("%")
        local line = vim.fn.line(".")
        vim.cmd("Rails test " .. file .. ":" .. line)
      end, { desc = "Rails: Test Current Line" })
    end,
  },

  -- Bundler integration
  {
    "tpope/vim-bundler",
    ft = { "ruby", "eruby" },
    cmd = { "Bundle", "Bopen", "Bsplit", "Btabedit" },
  },

  -- Rake integration
  {
    "tpope/vim-rake",
    ft = { "ruby", "eruby" },
    cmd = { "Rake", "A", "AD", "AS", "AT", "AV" },
  },

  -- Ruby extras
  {
    "vim-ruby/vim-ruby",
    ft = { "ruby", "eruby" },
    config = function()
      vim.g.ruby_indent_assignment_style = 'variable'
      vim.g.ruby_indent_block_style = 'do'
      vim.g.ruby_indent_hanging_elements = 1
    end,
  },

  -- Ruby end completion
  {
    "tpope/vim-endwise",
    ft = { "ruby", "eruby", "lua", "sh", "zsh", "vim" },
  },

  -- Tmux integration
  {
    "preservim/vimux",
    cmd = { "VimuxRunCommand", "VimuxOpenRunner" },
    keys = {
      { "<leader>vp", ":VimuxPromptCommand<CR>", desc = "Vimux: Prompt Command" },
      { "<leader>vl", ":VimuxRunLastCommand<CR>", desc = "Vimux: Run Last Command" },
      { "<leader>vo", ":VimuxOpenRunner<CR>", desc = "Vimux: Open Runner" },
      { "<leader>vc", ":VimuxCloseRunner<CR>", desc = "Vimux: Close Runner" },
    },
  },

  -- Better Ruby syntax and indentation
  {
    "kana/vim-textobj-user",
    dependencies = {
      "nelstrom/vim-textobj-rubyblock",
    },
    ft = { "ruby", "eruby" },
  },

  -- Ruby block text objects
  {
    "nelstrom/vim-textobj-rubyblock",
    ft = { "ruby", "eruby" },
    dependencies = { "kana/vim-textobj-user" },
  },
}
