return {
  -- TypeScript / JavaScript helper
  {
    "jose-elias-alvarez/typescript.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("typescript").setup({})
    end,
  },

  -- Terminal for debugging
  { "akinsho/toggleterm.nvim", config = true },
  
  -- Debugger
  { "mfussenegger/nvim-dap" },
  { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap" }, config = true },

  -- Mason tools for JavaScript
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "typescript-language-server",
          "prettier",
          "eslint-lsp",
        },
        auto_update = false,
        run_on_start = false,
      })
    end,
  },
}
