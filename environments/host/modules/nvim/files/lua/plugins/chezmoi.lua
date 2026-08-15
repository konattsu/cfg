vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = vim.fn.resolve(vim.fn.stdpath "data" .. "/../chezmoi/dot_config/nvim/*"),
  callback = function(event)
    vim.schedule(function() require("chezmoi.commands.__edit").watch(event.buf) end)
  end,
})

return {
  "xvzc/chezmoi.nvim",
  opts = {
    edit = {
      watch = true,
      force = false,
    },
    notification = {
      on_open = true,
      on_apply = true,
      on_watch = true,
    },
  },
}
