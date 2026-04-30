local M = {}

local ns = vim.api.nvim_create_namespace("org-links")

local defaults = {
  filetypes = { "org" },
  hl_group = "Underlined",
}

M.config = vim.deepcopy(defaults)

local function is_enabled_ft(bufnr)
  local ft = vim.bo[bufnr].filetype
  for _, allowed in ipairs(M.config.filetypes) do
    if ft == allowed then
      return true
    end
  end
  return false
end

-- Match [[url][desc]]
local function find_links(line)
  local results = {}
  local start = 1

  while true do
    local s, e, url, desc = line:find("%[%[([^%]]-)%]%[([^%]]-)%]%]", start)
    if not s then
      break
    end

    table.insert(results, {
      start_col = s - 1, -- 0-based
      end_col = e,       -- exclusive for nvim extmarks
      url = url,
      desc = desc,
    })

    start = e + 1
  end

  return results
end

local function set_window_options(winid)
  -- window-local options must be set on the window, not the buffer
  vim.wo[winid].conceallevel = 2
  vim.wo[winid].concealcursor = ""
end

function M.refresh_window(winid)
  winid = winid or vim.api.nvim_get_current_win()

  if not vim.api.nvim_win_is_valid(winid) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if not is_enabled_ft(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    return
  end

  set_window_options(winid)

  -- Important limitation:
  -- extmarks live on the buffer, not per-window.
  -- So this implementation behaves correctly when a buffer is shown in one window.
  -- If the same buffer is visible in multiple windows with different cursor lines,
  -- whichever window refreshes last will win.
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local cursor = vim.api.nvim_win_get_cursor(winid)
  local cursor_line = cursor[1] - 1 -- 0-based
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for row, line in ipairs(lines) do
    local row0 = row - 1

    if row0 ~= cursor_line then
      local links = find_links(line)

      for _, link in ipairs(links) do
        vim.api.nvim_buf_set_extmark(bufnr, ns, row0, link.start_col, {
          end_row = row0,
          end_col = link.end_col,
          conceal = "",
          --virt_text = { { "[" .. link.desc .. "]", M.config.hl_group } },
          virt_text = { { link.desc, M.config.hl_group } },
          virt_text_pos = "overlay",
          hl_mode = "combine",
          url = link.url,
        })
      end
    end
  end
end

function M.refresh_all_windows_for_buffer(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(winid) then
      M.refresh_window(winid)
    end
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  local group = vim.api.nvim_create_augroup("OrgLinks", { clear = true })

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWinEnter",
    "CursorMoved",
    "CursorMovedI",
    "TextChanged",
    "TextChangedI",
    "InsertLeave",
  }, {
    group = group,
    callback = function(args)
      M.refresh_all_windows_for_buffer(args.buf)
    end,
  })
end

return M
