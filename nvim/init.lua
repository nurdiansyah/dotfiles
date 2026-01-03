-- Ensure leaders are set before loading plugin manager
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
require("config.lazy")

-- Load core configurations
require("config.options")
require("config.keymaps")
require("config.autocmds")
