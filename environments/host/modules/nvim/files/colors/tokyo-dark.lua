vim.opt.termguicolors = true
vim.opt.background = "dark"

vim.cmd.highlight "clear"

if vim.fn.exists "syntax_on" == 1 then
  vim.cmd.syntax "reset"
end

vim.g.colors_name = "tokyo-dark"

local c = {
  bg = "#1a1b26",
  bg_dark = "#16161e",
  bg_highlight = "#292e42",
  fg = "#c0caf5",
  fg_dark = "#a9b1d6",
  fg_gutter = "#3b4261",
  comment = "#565f89",
  blue = "#7aa2f7",
  cyan = "#7dcfff",
  green = "#9ece6a",
  magenta = "#bb9af7",
  orange = "#ff9e64",
  red = "#f7768e",
  yellow = "#e0af68",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

hi("Normal", { fg = c.fg, bg = "NONE" })
hi("NormalNC", { fg = c.fg, bg = "NONE" })
hi("NormalFloat", { fg = c.fg, bg = "NONE" })
hi("FloatBorder", { fg = c.fg_gutter, bg = "NONE" })
hi("FloatTitle", { fg = c.yellow, bg = "NONE" })
hi("SignColumn", { bg = "NONE" })
hi("FoldColumn", { fg = c.fg_gutter, bg = "NONE" })
hi("EndOfBuffer", { fg = c.bg, bg = "NONE" })

hi("ColorColumn", { bg = c.bg_dark })
hi("Cursor", { fg = c.bg, bg = c.fg })
hi("CursorLine", { bg = c.bg_dark })
hi("CursorLineNr", { fg = c.yellow, bg = "NONE", bold = true })
hi("LineNr", { fg = c.fg_gutter, bg = "NONE" })
hi("MatchParen", { fg = c.cyan, bg = c.bg_highlight, bold = true })
hi("NonText", { fg = c.fg_gutter, bg = "NONE" })
hi("Pmenu", { fg = c.fg, bg = c.bg_dark })
hi("PmenuSel", { fg = c.fg, bg = c.bg_highlight })
hi("PmenuSbar", { bg = c.bg_dark })
hi("PmenuThumb", { bg = c.fg_gutter })
hi("Search", { fg = c.bg, bg = c.yellow })
hi("IncSearch", { fg = c.bg, bg = c.orange })
hi("Substitute", { fg = c.bg, bg = c.cyan })
hi("StatusLine", { fg = c.fg, bg = c.bg_dark })
hi("StatusLineNC", { fg = c.fg_gutter, bg = c.bg_dark })
hi("TabLine", { fg = c.fg_dark, bg = c.bg_dark })
hi("TabLineFill", { bg = "NONE" })
hi("TabLineSel", { fg = c.yellow, bg = "NONE" })
hi("VertSplit", { fg = c.bg_highlight, bg = "NONE" })
hi("Visual", { bg = c.bg_highlight })
hi("Whitespace", { fg = c.fg_gutter })
hi("WinSeparator", { fg = c.bg_highlight, bg = "NONE" })

hi("Comment", { fg = c.comment, italic = true })
hi("Constant", { fg = c.cyan })
hi("String", { fg = c.cyan })
hi("Character", { fg = c.cyan })
hi("Number", { fg = c.cyan })
hi("Boolean", { fg = c.cyan })
hi("Float", { fg = c.cyan })
hi("Identifier", { fg = c.blue })
hi("Function", { fg = c.blue })
hi("Statement", { fg = c.green })
hi("Conditional", { fg = c.green })
hi("Repeat", { fg = c.green })
hi("Label", { fg = c.green })
hi("Operator", { fg = c.fg })
hi("Keyword", { fg = c.green })
hi("Exception", { fg = c.green })
hi("PreProc", { fg = c.orange })
hi("Include", { fg = c.blue })
hi("Define", { fg = c.orange })
hi("Macro", { fg = c.orange })
hi("PreCondit", { fg = c.orange })
hi("Type", { fg = c.yellow })
hi("StorageClass", { fg = c.yellow })
hi("Structure", { fg = c.yellow })
hi("Typedef", { fg = c.yellow })
hi("Special", { fg = c.orange })
hi("SpecialChar", { fg = c.orange })
hi("Tag", { fg = c.blue })
hi("Delimiter", { fg = c.fg_dark })
hi("SpecialComment", { fg = c.comment, italic = true })
hi("Debug", { fg = c.red })
hi("Underlined", { fg = c.magenta, underline = true })
hi("Ignore", { fg = c.comment })
hi("Error", { fg = c.red })
hi("Todo", { fg = c.magenta, bold = true })

hi("DiffAdd", { fg = c.green, bg = "NONE" })
hi("DiffChange", { fg = c.yellow, bg = "NONE" })
hi("DiffDelete", { fg = c.red, bg = "NONE" })
hi("DiffText", { fg = c.blue, bg = "NONE" })

hi("DiagnosticError", { fg = c.red })
hi("DiagnosticWarn", { fg = c.yellow })
hi("DiagnosticInfo", { fg = c.blue })
hi("DiagnosticHint", { fg = c.cyan })
hi("DiagnosticOk", { fg = c.green })
hi("DiagnosticVirtualTextError", { fg = c.red, bg = "NONE" })
hi("DiagnosticVirtualTextWarn", { fg = c.yellow, bg = "NONE" })
hi("DiagnosticVirtualTextInfo", { fg = c.blue, bg = "NONE" })
hi("DiagnosticVirtualTextHint", { fg = c.cyan, bg = "NONE" })
hi("DiagnosticUnderlineError", { sp = c.red, undercurl = true })
hi("DiagnosticUnderlineWarn", { sp = c.yellow, undercurl = true })
hi("DiagnosticUnderlineInfo", { sp = c.blue, undercurl = true })
hi("DiagnosticUnderlineHint", { sp = c.cyan, undercurl = true })

hi("@comment", { link = "Comment" })
hi("@constant", { link = "Constant" })
hi("@string", { link = "String" })
hi("@number", { link = "Number" })
hi("@boolean", { link = "Boolean" })
hi("@function", { link = "Function" })
hi("@function.call", { link = "Function" })
hi("@variable", { fg = c.fg })
hi("@variable.builtin", { fg = c.orange })
hi("@keyword", { link = "Keyword" })
hi("@keyword.function", { fg = c.green })
hi("@type", { link = "Type" })
hi("@type.builtin", { fg = c.yellow })
hi("@property", { fg = c.fg_dark })
hi("@punctuation", { fg = c.fg_dark })
hi("@operator", { link = "Operator" })
