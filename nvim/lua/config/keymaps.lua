local ok, wk = pcall(require, "which-key")
local ok_state, state = pcall(require, "utils.state")

if not ok then
  -- Fallback to basic keymaps if which-key not available
  local keymap = vim.keymap
  keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
  keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
  keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
  keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
  keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
  keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
  return
end

-- Build base keymaps
local keymaps = {
  -- Window navigation
  { "<C-h>", "<C-w>h", desc = "Go to left window", mode = "n" },
  { "<C-j>", "<C-w>j", desc = "Go to lower window", mode = "n" },
  { "<C-k>", "<C-w>k", desc = "Go to upper window", mode = "n" },
  { "<C-l>", "<C-w>l", desc = "Go to right window", mode = "n" },

  -- Window resize
  { "<C-Up>", ":resize +2<CR>", desc = "Increase window height", mode = "n" },
  { "<C-Down>", ":resize -2<CR>", desc = "Decrease window height", mode = "n" },
  { "<C-Left>", ":vertical resize -2<CR>", desc = "Decrease window width", mode = "n" },
  { "<C-Right>", ":vertical resize +2<CR>", desc = "Increase window width", mode = "n" },

  -- Visual mode
  { "p", '"_dP', desc = "Paste without yanking", mode = "v" },
  { "J", ":m '>+1<CR>gv=gv", desc = "Move text down", mode = "v" },
  { "K", ":m '<-2<CR>gv=gv", desc = "Move text up", mode = "v" },

  -- Keep cursor centered
  { "J", "mzJ`z", desc = "Join lines", mode = "n" },
  { "<C-d>", "<C-d>zz", desc = "Scroll down", mode = "n" },
  { "<C-u>", "<C-u>zz", desc = "Scroll up", mode = "n" },
  { "n", "nzzzv", desc = "Next search result", mode = "n" },
  { "N", "Nzzzv", desc = "Previous search result", mode = "n" },

  -- Clear search
  { "<Esc>", ":noh<CR>", desc = "Clear search highlight", mode = "n" },

  -- File operations
  { "<leader>w", ":w<CR>", desc = "Save file", mode = "n" },
  { "<leader>q", ":q<CR>", desc = "Quit", mode = "n" },
  { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File explorer", mode = "n" },

  -- FZF Finder
  { "<leader>f", group = "Find (FZF)" },
  { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files", mode = "n" },
  { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep", mode = "n" },
  { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find buffers", mode = "n" },
  { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help tags", mode = "n" },

  -- Buffer operations
  { "<leader>b", group = "Buffer" },
  { "<S-l>", ":bnext<CR>", desc = "Next buffer", mode = "n" },
  { "<S-h>", ":bprevious<CR>", desc = "Previous buffer", mode = "n" },
  { "<leader>bd", ":bdelete<CR>", desc = "Delete buffer", mode = "n" },
  { "<leader>ba", ":%bdelete<CR>", desc = "Delete all buffers", mode = "n" },

  -- Git operations
  { "<leader>g", group = "Git" },

  -- LSP operations
  { "<leader>l", group = "LSP" },

  -- Debug operations
  { "<leader>d", group = "Debug" },

  -- Terminal operations
  { "<leader>t", group = "Terminal" },
}

-- Add profile-specific keymaps
if ok_state then
  if state.mode == "javascript" then
    table.insert(keymaps, { "<leader>tt", "<cmd>TestNearest<cr>", desc = "Run test", mode = "n" })
    table.insert(keymaps, { "<leader>dd", function()
      require("dap").continue()
    end, desc = "Debug Node", mode = "n" })
  elseif state.mode == "devops" then
    table.insert(keymaps, { "<leader>kk", "<cmd>KubeUtils contexts<cr>", desc = "K8s contexts", mode = "n" })
    table.insert(keymaps, { "<leader>kl", "<cmd>KubeUtils logs<cr>", desc = "K8s logs", mode = "n" })
  end
end

-- Register all keymaps with which-key
wk.add(keymaps)

