---@type LazySpec
return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "lua_ls",
        "gopls",
        "bashls",
        "taplo",
        "jsonls",
        "yamlls",
        "marksman",
        "dockerls",
        "docker_compose_language_service",
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    enabled = false,
  },
}
