return {
  { "h4ckm1n-dev/kube-utils-nvim" },
  { "towolf/vim-helm", ft = "helm" },
  { "hashivim/vim-terraform", ft = "terraform" },
  { "pearofducks/ansible-vim", ft = { "yaml", "ansible" } },
  { "b0o/schemastore.nvim" },

  -- Mason tools for DevOps
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "terraform-ls",
          "ansible-language-server",
          "yaml-language-server",
        },
        auto_update = false,
        run_on_start = false,
      })
    end,
  },
}
