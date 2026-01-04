local ok_state, state = pcall(require, "profiles._state")
if not ok_state then
  return
end

local ui = {
  javascript = { icon = "", color = "#6CC24A" },
  devops = { icon = "☸", color = "#326CE5" },
  auto   = { icon = "󰋗", color = "#AAAAAA" },
}

local ok, lualine = pcall(require, "lualine")
if not ok or not lualine then
  return
end

lualine.setup({
  sections = {
    lualine_c = {
      {
        function()
          local p = ui[state.mode] or ui.auto
          return p.icon .. " " .. state.mode:upper()
        end,
        color = function()
          local p = ui[state.mode] or ui.auto
          return { fg = p.color, gui = "bold" }
        end,
      },
      "filename",
    },
  },
})
