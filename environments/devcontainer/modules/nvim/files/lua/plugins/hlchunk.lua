local theme = {
  light_grey = "#656d73",
  red = "#e67e80",
}

return {
  "shellRaining/hlchunk.nvim",
  event = { "BufRead" },
  config = function()
    require("hlchunk").setup {
      ---@diagnostic disable-next-line: assign-type-mismatch
      chunk = {
        enable = true,
        notify = true,
        use_treesitter = false,
        -- details about support_filetypes and exclude_filetypes in https://github.com/shellRaining/hlchunk.nvim/blob/main/lua/hlchunk/utils/filetype.lua
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = ">",
        },
        style = {
          { fg = theme.light_grey },
          { fg = theme.red }, -- this fg is used to highlight wrong chunk
        },
        textobject = "",
        max_file_size = 1024 * 1024,
        error_sign = true,
        duration = 0,
        delay = 0,
      },

      indent = {
        enable = true,
        use_treesitter = false,
        chars = {
          "│",
        },
        style = {
          { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID "Whitespace"), "fg", "gui") },
        },
      },

      line_num = {
        enable = false,
        use_treesitter = false,
        style = theme.light_grey,
      },
    }
  end,
}
