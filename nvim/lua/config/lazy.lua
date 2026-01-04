-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
-- Allow project profiles (like VSCode) via env `NVIM_PROFILE` or vim.g.nvim_profile.
-- Profiles are additive to the base `plugins` list and live in `lua/plugins/profiles/*.lua`.
local profile = vim.g.nvim_profile or vim.env.NVIM_PROFILE
local specs = { { import = "plugins" } }
if profile and profile ~= "" then
  table.insert(specs, { import = "plugins.profiles." .. profile })
end

require("lazy").setup({
  spec = specs,
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
