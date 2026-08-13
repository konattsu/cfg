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

vim.opt.fixendofline = true
vim.opt.endofline = true

local trim_trailing_blank_lines_group = vim.api.nvim_create_augroup("trim_trailing_blank_lines", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = trim_trailing_blank_lines_group,
  pattern = "*",
  callback = function(args)
    local bufnr = args.buf
    local last = vim.api.nvim_buf_line_count(bufnr)

    while last > 1 do
      local line = vim.api.nvim_buf_get_lines(bufnr, last - 1, last, false)[1]
      if line and line:match "^%s*$" then
        vim.api.nvim_buf_set_lines(bufnr, last - 1, last, false, {})
        last = last - 1
      else
        break
      end
    end
  end,
})
