local c = require "colors.solarized_dark.palette"

local M = {}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

function M.apply()
  hi("@type.builtin.rust", { fg = c.green })
  hi("@constant.rust", { fg = c.blue })
  hi("@variable.parameter.rust", { fg = c.blue })
  hi("@variable.member.rust", { fg = c.blue })
  hi("@field.rust", { fg = c.blue })
  hi("@module.rust", { fg = c.orange })
  hi("@module.crate", { fg = c.green })
  hi("@module.crate.rust", { fg = c.green })
  hi("@module.builtin.rust", { fg = c.orange })
  hi("@constant.builtin.rust", { fg = c.green })
  hi("@keyword.import.rust", { fg = c.green })
  hi("@operator.rust", { fg = c.green })
  hi("@punctuation.delimiter.rust", { fg = c.green })
  hi("@punctuation.special.rust", { fg = c.green })
  hi("@punctuation.bracket.rust", { fg = c.base0 })
  hi("@attribute.rust", { fg = c.blue })
  hi("@attribute.builtin.rust", { fg = c.base1, bold = true })
  hi("@function.macro.rust", { fg = c.blue, bold = true })
  hi("@constant.macro.rust", { fg = c.blue, bold = true })
  hi("@character.rust", { fg = c.magenta })
  hi("@character.special.rust", { fg = c.magenta })

  hi("@lsp.type.const.rust", { fg = c.blue })
  hi("@lsp.type.parameter.rust", { fg = c.blue })
  hi("@lsp.type.function.rust", { fg = c.blue })
  hi("@lsp.type.macro.rust", { fg = c.blue, bold = true })
  hi("@lsp.type.operator.rust", { fg = c.green })
  hi("@lsp.type.lifetime.rust", { fg = c.base1, bold = true })
  hi("@lsp.type.selfKeyword.rust", { fg = c.green })
  hi("@lsp.type.selfTypeKeyword.rust", { fg = c.green })
  hi("@lsp.type.property.rust", { fg = c.blue })
  hi("@lsp.type.namespace.rust", { fg = c.orange })
  hi("@lsp.typemod.variable.readonly.rust", { fg = c.blue })
  hi("@lsp.typemod.function.defaultLibrary.rust", { fg = c.blue })
  hi("@lsp.typemod.macro.defaultLibrary.rust", { fg = c.blue, bold = true })
  hi("@lsp.typemod.type.defaultLibrary.rust", { fg = c.green })
  hi("@lsp.typemod.namespace.defaultLibrary.rust", { fg = c.orange })
end

return M
