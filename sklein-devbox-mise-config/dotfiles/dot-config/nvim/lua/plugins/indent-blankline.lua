return {
  "lukas-reineke/indent-blankline.nvim",
  opts = {
    whitespace = {
      -- Show dots for spaces with very low contrast
      highlight = "Whitespace",
    },
    scope = {
      -- Only show the indent line for current scope
      enabled = true,
      show_start = true,
      show_end = false,
      highlight = "IblScope",

      include = {
        node_type = {
          lua = {
            "function_definition",
            "function_declaration",
            "table_constructor",
            "if_statement",
            "for_statement",
            "while_statement",
          },
        },
      },
    },
  }
}
