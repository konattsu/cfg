return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<C-g>", "<Cmd>CodeDiff<CR>", desc = "Open Git diff explorer" },
  },
  opts = {
    diff = {
      layout = "side-by-side",
    },
  },
}
