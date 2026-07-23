if vim.fn.has "wsl" == 1 then
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
else
  vim.g.clipboard = {
    name = "osc52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy "+",
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste "+",
    },
  }
end
