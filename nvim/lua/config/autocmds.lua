local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local ok_state, state = pcall(require, "utils.state")
local ok_root, root = pcall(require, "utils.root")

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    (vim.h1 or vim.highlight).on_yank({ timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  group = augroup("strip_whitespace", { clear = true }),
  pattern = "*",
  command = [[%s/\s\+$//e]],
})

-- Auto-resize splits when window is resized
autocmd("VimResized", {
  group = augroup("resize_splits", { clear = true }),
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Close some filetypes with <q>
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = {
    "help",
    "qf",
    "lspinfo",
    "man",
    "checkhealth",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Auto set profile based on current working directory (guarded)
if ok_state and ok_root and root.detect then
  autocmd("DirChanged", {
    group = augroup("auto_profile", { clear = true }),
    callback = function()
      local mode = root.detect()
      if not mode then
        return
      end
      vim.g.nvim_profile = mode
      state.set(mode)
      pcall(vim.cmd, "Lazy reload")
    end,
  })
end

-- Load .nvim.lua if it exists in the current working directory
autocmd("VimEnter", {
  callback = function()
    local file = vim.fn.getcwd() .. "/.nvim.lua"
    if vim.fn.filereadable(file) == 1 then
      dofile(file)
    end
  end,
})
