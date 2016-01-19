local backend = require("textadept-spellchecker.backend")
---------------------------
-- Indicator click handler
---------------------------
local SUGGESTION_LIST = 4242 -- List id

-- autocomplete handler will be placed here to avoid presence of
-- many anonimous handlers in event table
local current_autocomplete_handler = false

-- Word begining and lenght for correct substitution of suggestion
local g_word_start = 0
local g_word_length = 0

-- only this autocomplete handler presents in event table
local function on_answer(word, suggestion)
  -- Handles autocompletion answer if it is nessesary
  -- then removes handler
  if current_autocomplete_handler and suggestion then
    current_autocomplete_handler(word, suggestion)
  end
  -- remove handler to avoid displaying suggestion again without click
  current_autocomplete_handler = false
end

local function on_suggestion_click(list_id, selection, pos)
  -- Handles click on item in suggestion list and replaces mistake
  if list_id == SUGGESTION_LIST then
    if selection ~= _L["Add to personal dictionary"] then
      buffer:delete_range(g_word_start, g_word_length)
      buffer:insert_text(buffer.current_pos, selection)
    else
      -- TODO: addition to the dictionary
      ui.print("Spellchecker: Dictionary addition not implemented yet")
    end
  end
end

local function on_indicator_click(pos, mod)
  -- Handles click on indicator and shows suggestion menu
  if mod ~= 0 then return end -- no modificators should be pressed
  local word_start = buffer:word_start_position(pos, false)
  local word_end = buffer:word_end_position(pos, false)
  g_word_start = word_start
  local word = buffer:text_range(word_start, word_end)
  current_autocomplete_handler = function(origin_word, suggestions)
    g_word_length = origin_word:len()
    local old_separator = buffer.auto_c_separator
    buffer.auto_c_separator = string.byte(",")
    buffer:user_list_show(SUGGESTION_LIST,
      suggestions:gsub(", ",",")..",".._L["Add to personal dictionary"]
    )
    buffer.auto_c_separator = old_separator
  end
  local checker = backend.get_checker()
  checker:write(word.."\n")
end

local _M = {}

function _M.connect_events()
  events.connect(events.INDICATOR_CLICK, on_indicator_click)
  events.connect(backend.ANSWER, on_answer)
  events.connect(events.USER_LIST_SELECTION, on_suggestion_click)
end

function _M.disconnect_events()
  events.disconnect(events.INDICATOR_CLICK, on_indicator_click)
  events.disconnect(backend.ANSWER, on_answer)
  events.disconnect(events.USER_LIST_SELECTION, on_suggestion_click)
end

return _M