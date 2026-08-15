return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      filetypes = { extension = {
        pcss = "postcss",
        postcss = "postcss",
      } },
      treesitter = { ensure_installed = { "html", "css", "scss", "styled" } },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function() vim.treesitter.language.register("scss", { "less", "postcss" }) end,
  },
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      servers = {
        "html",
        "cssls",
      },
      config = {
        html = {
          filetypes = { "html" },
          cmd = { "vscode-html-language-server", "--stdio" },
          init_options = { provideFormatter = false },
        },
        cssls = { cmd = { "vscode-css-language-server", "--stdio" }, init_options = { provideFormatter = false } },
      },
    },
  },
  {
    "nvim-mini/mini.icons",
    optional = true,
    opts = {
      filetype = {
        postcss = { glyph = "󰌜", hl = "MiniIconsOrange" },
      },
    },
  },
}
