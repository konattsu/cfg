return {
  "monaqa/dial.nvim",
  keys = { "<C-a>", "<C-x>" },
  config = function()
    local map = vim.keymap.set
    local dial = require "dial.map"
    map("v", "<C-x>", function() return dial.manipulate("decrement", "visual") end, { desc = "Increment" })

    map("v", "<C-a>", function() return dial.manipulate("increment", "visual") end, { desc = "decrement" })

    map("n", "<C-x>", function() return dial.manipulate("decrement", "normal") end, { desc = "Increment" })

    map("n", "<C-a>", function() return dial.manipulate("increment", "normal") end, { desc = "decrement" })

    local augend = require "dial.augend"

    require("dial.config").augends:register_group {
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.date.alias["%Y/%m/%d"],
        augend.constant.alias.bool,
        augend.semver.alias.semver,
        augend.date.new {
          pattern = "%B", -- titlecased month names
          default_kind = "day",
        },
        augend.constant.new {
          elements = {
            "january",
            "february",
            "march",
            "april",
            "may",
            "june",
            "july",
            "august",
            "september",
            "october",
            "november",
            "december",
          },
          word = true,
          cyclic = true,
        },
        augend.constant.new {
          elements = {
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday",
          },
          word = true,
          cyclic = true,
        },
        augend.constant.new {
          elements = {
            "monday",
            "tuesday",
            "wednesday",
            "thursday",
            "friday",
            "saturday",
            "sunday",
          },
          word = true,
          cyclic = true,
        },
        augend.case.new {
          types = { "camelCase", "PascalCase", "snake_case", "SCREAMING_SNAKE_CASE" },
        },
      },
    }
  end,
}
