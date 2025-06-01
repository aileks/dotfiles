return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "olimorris/neotest-rspec",
      "zidhuss/neotest-minitest",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          -- Ruby/Rails testing
          require("neotest-rspec")({
            rspec_cmd = function()
              return vim.tbl_flatten({
                "bundle",
                "exec",
                "rspec",
              })
            end,
            transform_spec_path = function(path)
              local prefix = require('neotest-rspec').root(path)
              return string.sub(path, string.len(prefix) + 2, -1)
            end,
            results_path = "tmp/rspec.output"
          }),

          require("neotest-minitest")({
            test_cmd = function()
              return vim.tbl_flatten({
                "bundle",
                "exec",
                "ruby",
              })
            end
          }),

          -- Python testing
          require("neotest-python")({
            dap = {
              justMyCode = false,
              console = "integratedTerminal",
            },
            args = { "--log-level", "DEBUG", "--quiet" },
            runner = "pytest",
            python = ".venv/bin/python",
            pytest_discover_instances = true,
          }),

          -- JavaScript/TypeScript testing
          require("neotest-jest")({
            jestCommand = "npm test --",
            jestConfigFile = "jest.config.js",
            env = { CI = true },
            cwd = function()
              return vim.fn.getcwd()
            end,
          }),

          require("neotest-vitest")({
            filter_dir = function(name, rel_path, root)
              return name ~= "node_modules"
            end,
          }),
        },

        -- UI configuration
        icons = {
          child_indent = "│",
          child_prefix = "├",
          collapsed = "─",
          expanded = "╮",
          failed = "✖",
          final_child_indent = " ",
          final_child_prefix = "╰",
          non_collapsible = "─",
          passed = "✓",
          running = "◐",
          running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
          skipped = "ⓢ",
          unknown = "?"
        },

        floating = {
          border = "rounded",
          max_height = 0.6,
          max_width = 0.6,
          options = {}
        },

        highlights = {
          adapter_name = "NeotestAdapterName",
          border = "NeotestBorder",
          dir = "NeotestDir",
          expand_marker = "NeotestExpandMarker",
          failed = "NeotestFailed",
          file = "NeotestFile",
          focused = "NeotestFocused",
          indent = "NeotestIndent",
          marked = "NeotestMarked",
          namespace = "NeotestNamespace",
          passed = "NeotestPassed",
          running = "NeotestRunning",
          select_win = "NeotestWinSelect",
          skipped = "NeotestSkipped",
          target = "NeotestTarget",
          test = "NeotestTest",
          unknown = "NeotestUnknown"
        },

        output = {
          enabled = true,
          open_on_run = "short",
        },

        output_panel = {
          enabled = true,
          open = "botright split | resize 15",
        },

        quickfix = {
          enabled = true,
          open = false,
        },

        run = {
          enabled = true,
        },

        running = {
          concurrent = true,
        },

        status = {
          enabled = true,
          signs = true,
          virtual_text = false,
        },

        strategies = {
          integrated = {
            height = 40,
            width = 120,
          },
        },

        summary = {
          animated = true,
          enabled = true,
          expand_errors = true,
          follow = true,
          mappings = {
            attach = "a",
            clear_marked = "M",
            clear_target = "T",
            debug = "d",
            debug_marked = "D",
            expand = { "<CR>", "<2-LeftMouse>" },
            expand_all = "e",
            help = "?",
            jumpto = "i",
            mark = "m",
            next_failed = "J",
            output = "o",
            prev_failed = "K",
            run = "r",
            run_marked = "R",
            short = "O",
            stop = "u",
            target = "t",
            watch = "w"
          },
          open = "botright vsplit | vertical resize 50"
        },
      })

      -- Keymaps
      local keymap = vim.keymap

      -- Test running
      keymap.set("n", "<leader>tn", function()
        require("neotest").run.run()
      end, { desc = "Test: Run Nearest" })

      keymap.set("n", "<leader>tf", function()
        require("neotest").run.run(vim.fn.expand("%"))
      end, { desc = "Test: Run File" })

      keymap.set("n", "<leader>td", function()
        require("neotest").run.run({ strategy = "dap" })
      end, { desc = "Test: Debug Nearest" })

      keymap.set("n", "<leader>ts", function()
        require("neotest").run.stop()
      end, { desc = "Test: Stop" })

      keymap.set("n", "<leader>ta", function()
        require("neotest").run.run({ suite = true })
      end, { desc = "Test: Run All" })

      -- Test output and summary
      keymap.set("n", "<leader>to", function()
        require("neotest").output.open({ enter = true, auto_close = true })
      end, { desc = "Test: Show Output" })

      keymap.set("n", "<leader>tO", function()
        require("neotest").output_panel.toggle()
      end, { desc = "Test: Toggle Output Panel" })

      keymap.set("n", "<leader>tS", function()
        require("neotest").summary.toggle()
      end, { desc = "Test: Toggle Summary" })

      -- Test navigation
      keymap.set("n", "]t", function()
        require("neotest").jump.next({ status = "failed" })
      end, { desc = "Test: Next Failed" })

      keymap.set("n", "[t", function()
        require("neotest").jump.prev({ status = "failed" })
      end, { desc = "Test: Previous Failed" })

      -- Watch mode
      keymap.set("n", "<leader>tw", function()
        require("neotest").watch.toggle(vim.fn.expand("%"))
      end, { desc = "Test: Toggle Watch" })
    end,
  },

  -- Coverage reporting
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "Coverage",
      "CoverageLoad",
      "CoverageShow",
      "CoverageHide",
      "CoverageToggle",
      "CoverageClear",
    },
    config = function()
      require("coverage").setup({
        auto_reload = true,
        auto_reload_timeout_ms = 500,
        commands = true,
        highlights = {
          covered = { fg = "#A3E635" },
          uncovered = { fg = "#F87171" },
        },
        signs = {
          covered = { hl = "CoverageCovered", text = "▎" },
          uncovered = { hl = "CoverageUncovered", text = "▎" },
        },
        summary = {
          min_coverage = 80.0,
        },
        lang = {
          ruby = {
            coverage_command = "bundle exec rspec",
            coverage_file = "coverage/.resultset.json",
          },
          python = {
            coverage_command = "coverage json --fail-under=0 -q",
            coverage_file = "coverage.json",
          },
          javascript = {
            coverage_command = "npm test -- --coverage --watchAll=false",
            coverage_file = "coverage/coverage-final.json",
          },
        },
      })

      vim.keymap.set("n", "<leader>tc", ":Coverage<CR>", { desc = "Test: Show Coverage" })
      vim.keymap.set("n", "<leader>tC", ":CoverageToggle<CR>", { desc = "Test: Toggle Coverage" })
    end,
  },
}
