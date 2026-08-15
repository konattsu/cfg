return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    mappings = {
      n = {
        ["<C-p>"] = { function() require("snacks").picker.files() end, desc = "Find files" },
        ["<leader>fi"] = { function() require("snacks").picker.highlights() end, desc = "Find highlights" },
        ["<leader>/"] = { function() require("snacks").picker.grep() end, desc = "Search project" },
        ["<leader>sp"] = { function() require("snacks").picker.grep() end, desc = "Search project" },
        ["<leader>sg"] = { function() require("snacks").picker.grep() end, desc = "Search project" },
      },
      x = {
        ["<leader>sp"] = { function() require("snacks").picker.grep() end, desc = "Search project" },
      },
    },
  },
}
