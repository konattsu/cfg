return {
  { import = "astrocommunity.lsp.nvim-lsp-file-operations" },
  {
    "AstroNvim/astrocore",
    optional = true,
    ---@type AstroCoreOpts
    opts = {
      treesitter = { ensure_installed = { "javascript", "typescript", "tsx", "jsdoc" } },
    },
  },
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      servers = { "ts_ls" },
      config = {
        ts_ls = {
          filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
          settings = {
            typescript = {
              format = { enable = false },
              updateImportsOnFileMove = { enabled = "always" },
            },
            javascript = {
              format = { enable = false },
              updateImportsOnFileMove = { enabled = "always" },
            },
          },
        },
      },
    },
  },
  {
    "nvim-mini/mini.icons",
    optional = true,
    opts = function(_, opts)
      if not opts.file then opts.file = {} end
      opts.file[".nvmrc"] = { glyph = "", hl = "MiniIconsGreen" }
      opts.file[".node-version"] = { glyph = "", hl = "MiniIconsGreen" }
      opts.file["package.json"] = { glyph = "", hl = "MiniIconsGreen" }
      opts.file["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" }
      opts.file["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" }
      opts.file["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" }
    end,
  },
}
