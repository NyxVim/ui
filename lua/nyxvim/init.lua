local api = vim.api
local config = require "nyxconfig"
local new_cmd = api.nvim_create_user_command

vim.o.statusline = "%!v:lua.require('nyxvim.stl." .. config.ui.statusline.theme .. "')()"

if config.ui.tabufline.enabled then
  require "nyxvim.tabufline.lazyload"
end

-- Command to toggle NyxDash
new_cmd("Nydash", function()
  if vim.g.nyxdash_displayed then
    require("nyxvim.tabufline").close_buffer()
  else
    require("nyxvim.nyxdash").open()
  end
end, {})

new_cmd("NyxCheatsheet", function()
  if vim.g.nyxcheatsheet_displayed then
    vim.cmd "bw"
  else
    require("nyxvim.cheatsheet." .. config.cheatsheet.theme)()
  end
end, {})

vim.schedule(function()
  -- load nyxdash only on empty file
  if config.ui.nyxdash.load_on_startup then
    local buf_lines = api.nvim_buf_get_lines(0, 0, 1, false)
    local no_buf_content = api.nvim_buf_line_count(0) == 1 and buf_lines[1] == ""
    local bufname = api.nvim_buf_get_name(0)

    if bufname == "" and no_buf_content then
      require("nyxvim.nyxdash").open()
    end
  end

  require "nyxvim.au"
end)

if vim.version().minor < 10 then
  vim.notify "Please update neovim version to v0.10 at least! NyxVim only supports v0.10+"
end
