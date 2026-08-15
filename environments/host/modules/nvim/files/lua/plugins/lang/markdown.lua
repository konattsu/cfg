return {
  {
    "AstroNvim/astrocore",
    optional = true,
    ---@type AstroCoreOpts
    opts = {
      treesitter = { ensure_installed = { "markdown", "markdown_inline" } },
      autocmds = {
        markdown_disable_completion = {
          {
            event = "FileType",
            pattern = "markdown",
            desc = "Disable completion in Markdown buffers",
            callback = function(args) vim.b[args.buf].completion = false end,
          },
        },
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      servers = { "marksman" },
    },
  },
}
