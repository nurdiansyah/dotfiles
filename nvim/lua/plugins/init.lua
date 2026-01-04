return {
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

  -- Fuzzy finder
  {
    "ibhagwan/fzf-lua",
    config = function()
      local fzf = require("fzf-lua")
      local actions = fzf.actions
      fzf.setup({
        "max-perf",
        winopts = {
          preview = {
            layout = "vertical",
          },
        },
        keymap = {
          fzf = {
            ["ctrl-q"] = "select-all+accept",
          },
        },
      })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      local setup = function()
        configs.setup({
          ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python", "java", "bash", "yaml", "json", "html", "css", "tsx", "terraform" },
          highlight = { enable = true },
          indent = { enable = true },
        })
      end

      if not ok then
        vim.schedule(function()
          local ok2, configs2 = pcall(require, "nvim-treesitter.configs")
          if ok2 then
            configs2.setup({
              ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python", "java", "bash", "yaml", "json", "html", "css", "tsx", "terraform" },
              highlight = { enable = true },
              indent = { enable = true },
            })
          end
        end)
        return
      end

      setup()
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
  },

  -- Mason tool installer (auto-install common LSP/formatters)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {},
        auto_update = false,
        run_on_start = false,
      })
    end,
  },

  -- Blink Completion Engine
  {
    "saghen/blink.cmp",
    version = "v1.*",
    opts = {
      completion = {
        accept = { auto_brackets = { enabled = true } },
        list = {
          selection = {
            preselect = function(ctx)
              return ctx.mode ~= "cmdline"
            end,
            auto_insert = true,
          },
        },
        menu = {
          draw = {
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
          },
        },
      },
      keymap = { preset = "enter" },
      appearance = {
        nerd_font_variant = "normal",
      },
      sources = {
        default = { "snippets", "lsp", "buffer", "path" },
        providers = {
          lsp = {
            async = true,
            fallbacks = {},
          },
        },
      },
      signature = { enabled = true, window = { show_documentation = false } },
    },
  },

  -- GitHub Copilot (AI completions)
  {
    "zbirenbaum/copilot.lua",
    lazy = false,
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = { accept = "<C-l>" },
      },
      panel = { enabled = true },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- Conform formatter
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          json = { "jq" },
          lua = { "stylua" },
          python = { "black" },
          rust = { "rustfmt" },
          sh = { "shfmt" },
          sql = { "sql-formatter" },
          xml = { "xmllint" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup()
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- Comment
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Which-key helper
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        preset = "modern",
        delay = 300,
      })
      
      -- Register leader key groups
      wk.add({
        { "<leader>f", group = "Find (FZF)" },
        { "<leader>b", group = "Buffer" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
        { "<leader>d", group = "Debug" },
        { "<leader>t", group = "Terminal" },
      })
    end,
  },
}
