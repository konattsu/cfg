if vim.fn.has "wsl" == 1 then
  vim.g.clipboard = "win32yank"
else
  vim.g.clipboard = "osc52"
end

vim.opt.clipboard:append "unnamedplus"
