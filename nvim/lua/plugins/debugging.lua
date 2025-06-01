return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "jay-babu/mason-nvim-dap.nvim",
      "mfussenegger/nvim-dap-python",
      "suketa/nvim-dap-ruby",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Setup mason-nvim-dap for automatic debug adapter installation
      require("mason-nvim-dap").setup({
        ensure_installed = {
          "python",
          "node2",
          "chrome",
        },
        automatic_installation = true,
        handlers = {
          function(config)
            require("mason-nvim-dap").default_setup(config)
          end,
        },
      })

      -- Python
      require("dap-python").setup("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python")

      -- Ruby
      require("dap-ruby").setup()

      -- Rails
      dap.configurations.ruby = vim.list_extend(dap.configurations.ruby or {}, {
        {
          type = "ruby",
          name = "Debug Rails server",
          request = "attach",
          localfs = true,
          port = 38698,
          server = "127.0.0.1",
          options = {
            source_filetype = "ruby",
          },
          message = "Make sure to run: bundle exec rdbg -n --open --port 38698 -c -- bin/rails server",
        },
        {
          type = "ruby",
          name = "Debug Rails test",
          request = "attach",
          localfs = true,
          port = 38699,
          server = "127.0.0.1",
          options = {
            source_filetype = "ruby",
          },
          message = "Make sure to run: bundle exec rdbg -n --open --port 38699 -c -- bin/rails test",
        }
      })

      -- JavaScript/TypeScript
      dap.configurations.javascript = {
        {
          name = "Launch",
          type = "node2",
          request = "launch",
          program = "${file}",
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = "inspector",
          console = "integratedTerminal",
        },
        {
          name = "Attach",
          type = "node2",
          request = "attach",
          processId = require("dap.utils").pick_process,
          cwd = vim.fn.getcwd(),
        },
      }

      dap.configurations.typescript = dap.configurations.javascript

      -- DAP UI
      dapui.setup({
        controls = {
          element = "repl",
          enabled = true,
          icons = {
            disconnect = "",
            pause = "",
            play = "",
            run_last = "",
            step_back = "",
            step_into = "",
            step_out = "",
            step_over = "",
            terminate = ""
          }
        },
        element_mappings = {},
        expand_lines = true,
        floating = {
          border = "single",
          mappings = {
            close = { "q", "<Esc>" }
          }
        },
        force_buffers = true,
        icons = {
          collapsed = "",
          current_frame = "",
          expanded = ""
        },
        layouts = {
          {
            elements = {
              { id = "scopes",      size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks",      size = 0.25 },
              { id = "watches",     size = 0.25 }
            },
            position = "left",
            size = 40
          },
          {
            elements = {
              { id = "repl",    size = 0.5 },
              { id = "console", size = 0.5 }
            },
            position = "bottom",
            size = 10
          }
        },
        mappings = {
          edit = "e",
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          repl = "r",
          toggle = "t"
        },
        render = {
          indent = 1,
          max_value_lines = 100
        }
      })

      -- Virtual text
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        filter_references_pattern = '<module',
        virt_text_pos = 'eol',
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil
      })

      -- Auto open/close UI
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      -- Keymaps
      local keymap = vim.keymap
      keymap.set("n", "<F5>", function() dap.continue() end, { desc = "Continue" })
      keymap.set("n", "<F10>", function() dap.step_over() end, { desc = "Step Over" })
      keymap.set("n", "<F11>", function() dap.step_into() end, { desc = "Step Into" })
      keymap.set("n", "<F12>", function() dap.step_out() end, { desc = "Step Out" })
      keymap.set("n", "<leader>db", function() dap.toggle_breakpoint() end, { desc = "Toggle Breakpoint" })
      keymap.set("n", "<leader>dB", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        { desc = "Conditional Breakpoint" })
      keymap.set("n", "<leader>dr", function() dap.repl.open() end, { desc = "Open REPL" })
      keymap.set("n", "<leader>dl", function() dap.run_last() end, { desc = "Run Last" })
      keymap.set("n", "<leader>du", function() dapui.toggle() end, { desc = "Toggle DAP UI" })
      keymap.set("n", "<leader>dc", function() dap.close() end, { desc = "Close DAP" })
      keymap.set("n", "<leader>dt", function() dap.terminate() end, { desc = "Terminate DAP" })
      keymap.set({ "n", "v" }, "<leader>de", function() dapui.eval() end, { desc = "Evaluate Expression" })

      -- Custom commands for Rails debugging
      vim.api.nvim_create_user_command("DebugRailsServer", function()
        print("Starting Rails server with debugger...")
        print("Run: bundle exec rdbg -n --open --port 42069 -c -- bin/rails server")
        print("Then attach using <F5> and select 'Debug Rails server'")
      end, {})

      vim.api.nvim_create_user_command("DebugRailsTest", function()
        local file = vim.fn.expand("%")
        print("Starting Rails test with debugger...")
        print("Run: bundle exec rdbg -n --open --port 69420 -c -- bin/rails test " .. file)
        print("Then attach using <F5> and select 'Debug Rails test'")
      end, {})
    end,
  },
}
