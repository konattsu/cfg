return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.dashboard = {
      preset = {
        header = table.concat({
          "                                                     ",
          "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
          "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
          "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
          "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
          "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
          "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
          "                                                     ",
        }, "\n"),
        keys = {
          {
            icon = "",
            desc = "Open Issues",
            key = "i",
            action = function() vim.fn.jobstart("gh issue list --web", { detach = true }) end,
          },

          {
            icon = " ",
            desc = "Open PRs",
            key = "p",
            action = function() vim.fn.jobstart("gh pr list --web", { detach = true }) end,
          },
          {
            icon = "󰈆",
            desc = "Quit",
            key = "q",
            action = ":q",
          },
        },
      },

      sections = {
        { section = "header" },
        { icon = " ", title = "Recent Files (cwd)", section = "recent_files", cwd = true, indent = 2, padding = 1 },
        { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { section = "keys", icon = "", title = "Action", padding = 2 },
        { section = "startup" },
      },
    }
  end,
}
