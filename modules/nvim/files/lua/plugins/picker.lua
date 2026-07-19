return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = {
        ["<C-p>"] = { function() require("snacks").picker.files() end, desc = "Find files" },
        ["<leader>fi"] = { function() require("snacks").picker.highlights() end, desc = "Find highlights" },
        ["<C-S-f>"] = { function() require("snacks").picker.grep() end, desc = "Find words" },
      },
      x = {
        ["<C-S-f>"] = { function() require("snacks").picker.grep() end, desc = "Find words" },
      },
    },
  },
}
