return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    optional = true,
    specs = {
      {
        "Cretezy/neo-tree-jj.nvim",
        dependencies = {
          {
            "nvim-neo-tree/neo-tree.nvim",
            opts = function(_, opts)
              table.insert(opts.sources, "jj")

              -- Replace git tab in neo-tree when in jj repo
              if require("neo-tree.sources.jj.utils").get_repository_root() then
                -- Remove git tab
                for i, source in ipairs(opts.source_selector.sources) do
                  if source.source == "git_status" then
                    table.remove(opts.source_selector.sources, i)
                    break
                  end
                end

                -- Add jj tab
                table.insert(opts.source_selector.sources, {
                  display_name = "󰊢 JJ",
                  source = "jj",
                })
              end
            end,
          },
        },
      },
    },
  },
  { "avm99963/vim-jjdescription", lazy = false },
  {
    "AstroNvim/astrocore",
    ---@param opts AstroCoreOpts
    opts = function(_, opts)
      local maps = assert(opts.mappings)

      if vim.fn.executable "lazyjj" == 1 then
        maps.n["<Leader>jl"] = {
          function()
            local astro = require "astrocore"
            local worktree = astro.file_worktree()
            local flags = worktree and ("--path '%s'"):format(worktree.toplevel, worktree.gitdir) or ""
            astro.toggle_term_cmd { cmd = "lazyjj " .. flags, direction = "float" }
          end,
          desc = "lazyjj",
        }
      end

      if vim.fn.executable "jjui" == 1 then
        maps.n["<Leader>ju"] = {
          function()
            local astro = require "astrocore"
            astro.toggle_term_cmd { cmd = "jjui", direction = "float" }
          end,
          desc = "jjui",
        }
      end
    end,
  },
}
