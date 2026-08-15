return {
  {
    "AstroNvim/astrocore",
    optional = true,
    ---@type AstroCoreOpts
    opts = {
      treesitter = { ensure_installed = { "lua", "luap" } },
    },
  },
  {
    "AstroNvim/astrolsp",
    optional = true,
    ---@type AstroLSPOpts
    opts = {
      servers = {
        "lua_ls",
      },
      config = {
        lua_ls = {
          filetypes = { "lua" },
          cmd = { "lua-language-server" },
          settings = {
            Lua = {
              codeLens = {
                enable = false,
              },
              hint = {
                enable = true,
                arrayIndex = "Disable",
              },
            },
          },
        },
      },
    },
  },
}
