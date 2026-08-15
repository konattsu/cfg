return {
  "nvim-treesitter/nvim-treesitter-context",
  event = "BufRead",
  cmd = { "TSContext" },
  opts = {
    mode = "topline",
    max_lines = 3,
  },
}
