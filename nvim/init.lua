-- Ensure leaders are set before loading plugin manager
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Nonaktifkan perilaku default Space
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Config
require("config.lazy")
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.statusline")
