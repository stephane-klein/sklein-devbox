-- ne fonctionne pas
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  keys = {
    {
      "<leader><Left>",
      function()
        require("smart-splits").move_cursor_left()
      end,
      desc = "Move to left split",
    },
    {
      "<leader><Right>",
      function()
        require("smart-splits").move_cursor_right()
      end,
      desc = "Move to right split",
    },
    {
      "<leader><Up>",
      function()
        require("smart-splits").move_cursor_up()
      end,
      desc = "Move to upper split",
    },
    {
      "<leader><Down>",
      function()
        require("smart-splits").move_cursor_down()
      end,
      desc = "Move to lower split",
    },
  },
}
