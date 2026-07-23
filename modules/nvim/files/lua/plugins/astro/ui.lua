---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "everforest",
    highlights = {
      init = function()
        local get_hlgroup = require("astroui").get_hlgroup

        local bg = get_hlgroup("Normal").bg
        local bg_alt = get_hlgroup("Visual").bg
        local foreground = get_hlgroup("Normal").fg
        local green = get_hlgroup("String").fg
        local red = get_hlgroup("Error").fg
        local gray = get_hlgroup("Comment").fg

        local function transparent_bg(group)
          local highlight = get_hlgroup(group)
          highlight.bg = "NONE"
          return highlight
        end

        return {
          Normal = transparent_bg "Normal",
          NormalNC = transparent_bg "NormalNC",
          NormalFloat = transparent_bg "NormalFloat",
          SignColumn = transparent_bg "SignColumn",
          EndOfBuffer = transparent_bg "EndOfBuffer",
          NeoTreeNormal = transparent_bg "NeoTreeNormal",
          NeoTreeNormalNC = transparent_bg "NeoTreeNormalNC",
          WhichKeyNormal = get_hlgroup "NormalFloat",
          WhichKeyBorder = get_hlgroup "FloatBorder",
          WhichKeyTitle = get_hlgroup "FloatTitle",
          SnacksPickerBorder = { fg = bg_alt, bg = "NONE" },
          SnacksPicker = transparent_bg "SnacksPicker",
          SnacksPickerPreviewBorder = { fg = bg, bg = "NONE" },
          SnacksPickerPreview = transparent_bg "SnacksPickerPreview",
          SnacksPickerPreviewTitle = { fg = bg, bg = green },
          SnacksPickerBoxBorder = { fg = bg, bg = "NONE" },
          SnacksPickerInputBorder = { fg = bg, bg = "NONE" },
          SnacksPickerInputSearch = { fg = red, bg = "NONE" },
          SnacksPickerDir = { fg = foreground },
          SnacksPickerListBorder = { fg = bg, bg = "NONE" },
          SnacksPickerList = transparent_bg "SnacksPickerList",
          SnacksPickerListTitle = { fg = bg, bg = "NONE" },
          LspCodeLens = { fg = gray },
          LineNr = { fg = gray },
          SnacksDashboardDir = { fg = gray },
        }
      end,
    },
    icons = {
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}
