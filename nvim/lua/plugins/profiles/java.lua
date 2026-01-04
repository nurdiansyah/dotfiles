return {
  -- Java development
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },

  -- Mason tools for Java
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "jdtls",
        },
        auto_update = false,
        run_on_start = false,
      })
    end,
  },
}
