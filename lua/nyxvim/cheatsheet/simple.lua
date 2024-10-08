local api = vim.api
local genStr = string.rep

dofile(vim.g.base46_cache .. "nyxcheatsheet")

api.nvim_create_autocmd("BufWinLeave", {
  callback = function()
    if vim.bo.ft == "nyxcheatsheet" then
      vim.g.nyxcheatsheet_displayed = false
    end
  end,
})

return function()
  local mappings_tb = {}
  require("nyxvim.cheatsheet").organize_mappings(mappings_tb)

  vim.g.nv_previous_buf = api.nvim_get_current_buf()

  local buf = api.nvim_create_buf(false, true)
  require("nyxvim.cheatsheet").create_fullsize_win(buf)

  local win = api.nvim_get_current_win()

  api.nvim_set_current_win(win)
  vim.wo[win].winhl = "NormalFloat:Normal"

  local centerPoint = api.nvim_win_get_width(win) / 2

  -- Find largest string i.e mapping desc among all mappings
  local largest_str = 0

  for _, section in pairs(mappings_tb) do
    for _, keymap in ipairs(section) do
      largest_str = largest_str > #keymap[1] + #keymap[2] and largest_str or #keymap[2] + #keymap[2]
    end
  end

  local lineNumsDesc = {}

  local result = {
    "",
    "                                      ",
    "                                      ",
    "█▀▀ █░█ █▀▀ ▄▀█ ▀█▀ █▀ █░█ █▀▀ █▀▀ ▀█▀",
    "█▄▄ █▀█ ██▄ █▀█ ░█░ ▄█ █▀█ ██▄ ██▄ ░█░",
    "                                      ",
    "                                      ",
    "",
  }

  for i, val in ipairs(result) do
    result[i] = genStr(" ", centerPoint - (vim.fn.strwidth(val) / 2) + 4) .. val .. genStr(" ", 12)
    lineNumsDesc[#lineNumsDesc + 1] = val == "" and "emptySpace" or "asciiHeader"
  end

  local horiz_index = 0

  local function Capitalize(str)
    return (str:gsub("^%l", string.upper))
  end

  local function addPadding(str)
    local padding = largest_str + 30 - #str
    return genStr(" ", padding / 2) .. Capitalize(str) .. genStr(" ", padding / 2)
  end

  local mapping_txt_endIndex = 0

  -- Store content in a table in a formatted way
  for card_name, section in pairs(mappings_tb) do
    -- Set section headings
    local heading = addPadding(card_name)
    local padded_heading = genStr(" ", centerPoint - #heading / 2) .. heading -- centered text
    local padding_chars = genStr(" ", centerPoint + (#heading / 2) + 2)

    result[#result + 1] = "  " .. padded_heading
    lineNumsDesc[#lineNumsDesc + 1] = "heading"

    result[#result + 1] = padding_chars
    lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"

    -- Set section mappings : description & keybinds
    for _, keymap in ipairs(section) do
      local emptySpace = largest_str + 30 - #keymap[1] - #keymap[2] - 10

      local map = Capitalize(keymap[1]) .. genStr(" ", emptySpace) .. keymap[2]
      local txt = genStr(" ", centerPoint - #map / 2) .. map

      result[#result + 1] = "   " .. txt .. "   "

      if mapping_txt_endIndex == 0 then
        mapping_txt_endIndex = #result[#result]
      end

      lineNumsDesc[#lineNumsDesc + 1] = "mapping"

      result[#result + 1] = padding_chars
      lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"

      if horiz_index == 0 then
        horiz_index = math.floor(centerPoint - math.floor(#map / 2))
      end
    end

    -- add empty lines after a section
    result[#result + 1] = "  "
    result[#result + 1] = "  "

    lineNumsDesc[#lineNumsDesc + 1] = "paddingBlock"
    lineNumsDesc[#lineNumsDesc + 1] = "emptySpace"
  end

  -- draw content on buffer
  api.nvim_buf_set_lines(buf, 3, -1, false, result)

  -- set highlights
  local nyxcheatsheet = api.nvim_create_namespace "nyxcheatsheet"

  local hlgroups_types = {
    heading = "NyxVimHeading",
    mapping = "NyxVimSection",
    paddingBlock = "NyxVimSection",
    asciiHeader = "NyxVimAsciiHeader",
    emptySpace = "none",
  }

  for i, val in ipairs(lineNumsDesc) do
    api.nvim_buf_add_highlight(
      buf,
      nyxcheatsheet,
      hlgroups_types[val],
      i,
      horiz_index,
      val == "asciiHeader" and -1 or mapping_txt_endIndex
    )
  end

  api.nvim_set_current_buf(buf)

  require("nyxvim.utils").set_cleanbuf_opts "nyxcheatsheet"

  vim.keymap.set("n", "<ESC>", function()
    vim.cmd "q"
  end, { buffer = buf })
end
