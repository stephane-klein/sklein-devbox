return {
  name = "meson compile",
  builder = function()
    return {
      cmd = { "meson", "compile", "-C", "build" },
      components = {
        { "on_output_quickfix", open = true },
        "on_result_diagnostics",
        "default",
      },
    }
  end,
  condition = {
    callback = function()
      return vim.fn.filereadable("meson.build") == 1
    end,
  },
}
