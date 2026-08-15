return {
  "HiPhish/rainbow-delimiters.nvim",
  event = "BufReadPost",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("rainbow-delimiters.setup").setup {
      strategy = {
        [""] = "rainbow-delimiters.strategy.global",
      },
      query = {
        [""] = "rainbow-delimiters",
      },
      priority = {
        [""] = 110,
      },
      highlight = {
        "RainbowDelimiterRed",
        "RainbowDelimiterYellow",
        "RainbowDelimiterBlue",
      },
    }
  end,
}
