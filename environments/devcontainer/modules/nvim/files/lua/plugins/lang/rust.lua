return {
  {
    "AstroNvim/astrocore",
    optional = true,
    ---@type AstroCoreOpts
    opts = {
      treesitter = { ensure_installed = { "rust" } },
    },
  },
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      servers = { "rust_analyzer" },
      config = {
        rust_analyzer = {
          filetypes = { "rust" },
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = false,
              inlayHints = {
                enable = false,
              },
            },
          },
        },
      },
    },
  },
}
