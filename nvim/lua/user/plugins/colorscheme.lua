return {
  'Shatur/neovim-ayu',
  config = function()
    require('ayu').setup({
      overrides = {
        -- Transparency options
        Normal = { bg = "None" },
        ColorColumn = { bg = "None" },
        SignColumn = { bg = "None" },
        Folded = { bg = "None" },
        FoldColumn = { bg = "None" },
        CursorLine = { bg = "None" },
        CursorColumn = { bg = "None" },
        WhichKeyFloat = { bg = "None" },
        VertSplit = { bg = "None" },
        LineNr = { bg = "#0F151E" },
      }
    })

    vim.cmd.colorscheme('ayu')
  end
}
