local M = {}
local api = vim.api
local fn = vim.fn

dofile(vim.g.base46_cache .. "nyxdash")

local config = require("nyxconfig").ui.nyxdash

local headerAscii = config.header
local emmptyLine = string.rep(" ", vim.fn.strwidth(headerAscii[1]))

table.insert(headerAscii, 1, emmptyLine)
table.insert(headerAscii, 2, emmptyLine)

headerAscii[#headerAscii + 1] = emmptyLine
headerAscii[#headerAscii + 1] = emmptyLine

api.nvim_create_autocmd("BufLeave", {
  callback = function()
    if vim.bo.ft == "nyxdash" then
      vim.g.nyxdash_displayed = false
    end
  end,
})

local map = function(keys, action)
  for _, v in ipairs(keys) do
    vim.keymap.set("n", v, action, { buffer = true })
  end
end

M.open = function()
  local buttons = config.buttons
  local nyxdashWidth = #headerAscii[1] + 3

  local max_height = #headerAscii + 4 + (2 * #buttons) -- 4  = extra spaces i.e top/bottom
  local get_win_height = api.nvim_win_get_height

  vim.g.nv_previous_buf = vim.api.nvim_get_current_buf()

  local buf = vim.api.nvim_create_buf(false, true)
  local win = api.nvim_get_current_win()

  -- switch to larger win if cur win is small
  if nyxdashWidth + 6 > api.nvim_win_get_width(0) then
    vim.api.nvim_set_current_win(api.nvim_list_wins()[2])
    win = api.nvim_get_current_win()
  end

  api.nvim_win_set_buf(win, buf)

  local header = headerAscii

  local function addSpacing_toBtns(txt1, txt2)
    local btn_len = fn.strwidth(txt1) + fn.strwidth(txt2)
    local spacing = fn.strwidth(header[1]) - btn_len
    return txt1 .. string.rep(" ", spacing - 1) .. txt2 .. " "
  end

  local function addPadding_toHeader(str)
    local pad = (api.nvim_win_get_width(win) - fn.strwidth(str)) / 2
    return string.rep(" ", math.floor(pad)) .. str .. " "
  end

  local dashboard = {}

  for _, val in ipairs(header) do
    table.insert(dashboard, val .. " ")
  end

  for _, val in ipairs(buttons) do
    local str = type(val) ~= "table" and val() or nil
    table.insert(dashboard, str or addSpacing_toBtns(val[1], val[2]) .. " ")
    table.insert(dashboard, header[1] .. " ")
  end

  local result = {}

  -- make all lines available
  for i = 1, math.max(get_win_height(win), max_height) do
    result[i] = ""
  end

  local headerStart_Index = math.abs(math.floor((get_win_height(win) / 2) - (#dashboard / 2))) + 1 -- 1 = To handle zero case
  local abc = math.abs(math.floor((get_win_height(win) / 2) - (#dashboard / 2))) + 1 -- 1 = To handle zero case

  -- set ascii
  for _, val in ipairs(dashboard) do
    result[headerStart_Index] = addPadding_toHeader(val)
    headerStart_Index = headerStart_Index + 1
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, result)

  local nyxdash = api.nvim_create_namespace "nyxdash"
  local horiz_pad_index = math.floor((api.nvim_win_get_width(win) / 2) - (nyxdashWidth / 2)) - 2

  for i = abc, abc + #header do
    api.nvim_buf_add_highlight(buf, nyxdash, "NyxDashAscii", i, horiz_pad_index, -1)
  end

  for i = abc + #header - 2, abc + #dashboard do
    api.nvim_buf_add_highlight(buf, nyxdash, "NyxDashButtons", i, horiz_pad_index, -1)
  end

  api.nvim_win_set_cursor(win, { abc + #header, math.floor(vim.o.columns / 2) - 13 })

  local first_btn_line = abc + #header + 2
  local keybind_lineNrs = {}

  for _, _ in ipairs(buttons) do
    table.insert(keybind_lineNrs, first_btn_line - 2)
    first_btn_line = first_btn_line + 2
  end

  -- disable left/right
  map({ "h", "l", "<left>", "<right>" }, "")

  map({ "k", "<up>" }, function()
    local cur = fn.line "."
    local target_line = cur == keybind_lineNrs[1] and keybind_lineNrs[#keybind_lineNrs] or cur - 2
    api.nvim_win_set_cursor(win, { target_line, math.floor(vim.o.columns / 2) - 13 })
  end)

  map({ "j", "<down>" }, function()
    local cur = fn.line "."
    local target_line = cur == keybind_lineNrs[#keybind_lineNrs] and keybind_lineNrs[1] or cur + 2
    api.nvim_win_set_cursor(win, { target_line, math.floor(vim.o.columns / 2) - 13 })
  end)

  -- pressing enter on
  vim.keymap.set("n", "<CR>", function()
    for i, val in ipairs(keybind_lineNrs) do
      if val == fn.line "." then
        local action = buttons[i][3]

        if type(action) == "string" then
          vim.cmd(action)
        elseif type(action) == "function" then
          action()
        end
      end
    end
  end, { buffer = true })

  require("nyxvim.utils").set_cleanbuf_opts "nyxdash"
end

return M
