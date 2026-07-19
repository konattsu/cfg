return {
  {
    "folke/noice.nvim",
    event = { "VeryLazy" },
    keys = {
      {
        "<leader>fn",
        function() require("noice.integrations.snacks").open() end,
        desc = "Find notifications",
      },
    },
    opts = {
      lsp = {
        hover = { enabled = false },
        signature = { enabled = false },
        progress = { enabled = false },
        message = { enabled = false },
        -- Markdown 関連の monkey patch も無効のまま（既定はすべて false）
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
          ["vim.lsp.util.stylize_markdown"] = false,
          ["cmp.entry.get_documentation"] = false,
        },
      },

      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },

      messages = {
        view = "mini", -- default view for messages
        view_error = "mini", -- view for errors
        view_warn = "mini", -- view for warnings
        view_search = "mini",
      },
      presets = {
        bottom_search = true,
        long_message_to_split = true,
      },
    },
  },
}
