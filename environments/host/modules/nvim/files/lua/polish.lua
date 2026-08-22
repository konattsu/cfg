if vim.fn.has "wsl" == 1 then
  local win32yank = "win32yank.exe"
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = { win32yank, "-i", "--crlf" },
      ["*"] = { win32yank, "-i", "--crlf" },
    },
    paste = {
      ["+"] = { win32yank, "-o", "--lf" },
      ["*"] = { win32yank, "-o", "--lf" },
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

-- trim trailing whitespace on save
local trim_trailing_whitespace_group = vim.api.nvim_create_augroup("trim_trailing_whitespace", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = trim_trailing_whitespace_group,
  pattern = "*",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd [[keeppatterns %s/\s\+$//e]]
    vim.fn.winrestview(view)
  end,
})

-- trim trailing blank lines and insert finel newline on save
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

local function append_inspect_section(lines, title, items)
  table.insert(lines, "")
  table.insert(lines, title)

  if vim.tbl_isempty(items) then
    table.insert(lines, "  none")
    return
  end

  for _, item in ipairs(items) do
    for line in vim.inspect(item):gmatch "[^\n]+" do
      table.insert(lines, "  " .. line)
    end
  end
end

vim.api.nvim_create_user_command("InspectCapture", function(args)
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local inspected = vim.inspect_pos(bufnr, row, col)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local text = vim.api.nvim_buf_get_text(bufnr, row, col, row, col + 1, {})[1] or ""

  local lines = {
    ("InspectCapture: %s:%d:%d"):format(file ~= "" and file or "[No Name]", row + 1, col + 1),
    ("character: %s"):format(vim.inspect(text)),
  }

  append_inspect_section(lines, "treesitter", inspected.treesitter)
  append_inspect_section(lines, "semantic_tokens", inspected.semantic_tokens)
  append_inspect_section(lines, "syntax", inspected.syntax)
  append_inspect_section(lines, "extmarks", inspected.extmarks)

  if args.bang then vim.fn.setreg("+", table.concat(lines, "\n")) end

  vim.cmd "botright new"
  local out = vim.api.nvim_get_current_buf()
  vim.bo[out].buftype = "nofile"
  vim.bo[out].bufhidden = "wipe"
  vim.bo[out].swapfile = false
  vim.bo[out].filetype = "lua"
  vim.api.nvim_buf_set_name(out, "InspectCapture")
  vim.api.nvim_buf_set_lines(out, 0, -1, false, lines)
end, {
  bang = true,
  desc = "Capture cursor highlight inspection in a scratch buffer. Use ! to copy it.",
})
