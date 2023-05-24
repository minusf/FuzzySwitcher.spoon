--- === FuzzySwitcher ===
---
--- Live in the terminal and Spotlight too heavy for simple Application startup?
---
--- Spotlight indexing every single file creepy too much?
---
--- Fed up with `cmd+tab` constantly just to hit that right icon in a looong list?
---
--- This is a minimalist replacement that fuzzy selects both running and
--- not-yet-running Applications enabled by the amazing
--- <http://www.hammerspoon.org/>
---
--- Installation:
--- in `~/.hammerspoon/init.lua`:
---
--- hs.loadSpoon("FuzzySwitcher")
--- spoon.FuzzySwitcher:bindHotkeys({show_switcher = {{"cmd"}, "space"}})
--- spoon.FuzzySwitcher:start()
---
--- Disabling Spotlight
--- To hijack `cmd+space` with hammerspoon, disabling the spotlight keyboard
--- shortcut is not enough, it must be changed first to something else under
--- "Keyboard Shortcuts".
---
--- Spotlight indexing must be turned off for every volume individually, e.g.
--- `sudo mdutil -i off /`

local obj={}
obj.__index = obj


-- Configuration --

-- Folders to watch
obj.app_folders = {
  "/Applications",
  "/System/Applications",
  "/System/Applications/Utilities",
  -- pwd for the spoon is ~/.hammerspoon, so this equals to ~/Applications
  "../Applications",
}

-- These will never show up in the list
obj.app_ignore_list = {
  -- "AirPort Utility",
  -- "ColorSync Utility",
  -- "Dashboard",
  -- "Siri",
  -- "VoiceOver Utility",
}

-- The level of subfolders to search for Applications
obj.folder_depth = 1

-- Remember last selection in the popup
obj.remember_last = true


----------------------------------------------------------------------

-- Metadata
obj.name = "FuzzySwitcher"
obj.version = "0.1"
obj.author = "minusf@runbox.com"
obj.homepage = "https://github.com/minusf/FuzzySwitcher.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- "info" by default, change to "debug" to see all debug messages
obj.logger = hs.logger.new("FuzzySwitcher", "info")

obj.chooserPopup = nil
obj.prevFocusedWindow = nil
obj.full_app_list = {}

_s = function(s) return string.format("%s.%s", obj.name, s) end

function get_setting(s, default)
  return hs.settings.get(_s(s)) or default
end

function set_setting(s, value)
  hs.settings.set(_s(s), value)
end

function obj:processSelected(row)
  if row ~= nil then
    obj.logger.df("selected '%s'", row["text"])
    self.chooserPopup:hide()
    -- hs.application.open(row.text)
    hs.application.launchOrFocus(row.text)
  end
end

function is_ignored(app)
  if #obj.app_ignore_list ~= 0 then
    for b = 1, #obj.app_ignore_list do
      if string.find(app, obj.app_ignore_list[b]) ~= nil then
        obj.logger.f("ignoring '%s'", app)
        return true
      end
    end
  end
  return false
end

function process_folder(folder)
  obj.logger.f("reading '%s'", folder)

  local command = string.format(
    "find \"%s\" -maxdepth %s \\( -type d -or -type l \\) -name \"*.app\" -print0 " ..
    "| xargs -0 -n1 basename",
    folder,
    obj.folder_depth
  )
  obj.logger.df("running '%s'", command)
  local output = io.popen(command)

  local app_list = {}
  for line in output:lines() do
    local app_name = string.gsub(line, "%.app$", "")
    obj.logger.df("found '%s'", app_name)

    if is_ignored(app_name) == false then
      table.insert(app_list, app_name)
    end
  end

  obj.logger.df("app_list: %s", hs.inspect(app_list))
  return app_list
end

function obj:buildAppList()
  --
  -- mod_times: list of modifiation times for every item in app_folders
  -- app_lists: separate list of applications for every item in app_folders
  --
  -- When a folder's content changes, only that folder's list is rebuilt, together
  -- with the full_app_list (because it's a flat list).
  --
  local start_ts = hs.timer.secondsSinceEpoch()
  local saved_mod_times = get_setting("mod_times", {})
  local saved_app_lists = get_setting("app_lists", {})

  local list_changed = false

  obj.logger.df("full_app_list: %s", hs.inspect(self.full_app_list))

  for i = 1, #self.app_folders do
    local app_folder = self.app_folders[i]
    local app_list = saved_app_lists[app_folder]

    local mod_ts = saved_mod_times[app_folder]
    local new_mod_ts = hs.fs.attributes(app_folder, "modification")

    if new_mod_ts == nil then
      obj.logger.f("can't read '%s'", app_folder)
    elseif app_list == nil or mod_ts == nil or mod_ts < new_mod_ts then
      list_changed = true

      app_list = process_folder(app_folder)

      saved_mod_times[app_folder] = new_mod_ts
      saved_app_lists[app_folder] = app_list
    else
      obj.logger.f("no change in: '%s'", app_folder)
    end
  end

  if list_changed then
    obj.full_app_list = {}

    for k, v in pairs(saved_app_lists) do
      for i = 1, #v do
        table.insert(self.full_app_list, {text=v[i]})
      end
    end

    set_setting("mod_times", saved_mod_times)
    set_setting("app_lists", saved_app_lists)
  end

  obj.logger.df("saved_mod_times: %s", hs.inspect(saved_mod_times))
  obj.logger.df("saved_app_lists: %s", hs.inspect(saved_app_lists))

  obj.logger.df("full_app_list: %s", hs.inspect(self.full_app_list))
  obj.logger.f("total non-ignored apps: %s", #self.full_app_list)
  obj.logger.f("built list in: %s s", hs.timer.secondsSinceEpoch() - start_ts)

  return self.full_app_list
end

function obj:showSwitcher()
  if self.chooserPopup ~= nil then
    self.chooserPopup:refreshChoicesCallback()
    self.prevFocusedWindow = hs.window.focusedWindow()
    if obj.remember_last == false then
      self.chooserPopup:query("")
    end
    self.chooserPopup:show()
  else
    hs.notify.show("FuzzySwitcher not properly initialized", "Did you call FuzzySwitcher:start()?", "")
  end
end

function obj:bindHotkeys(mapping)
  local def = {show_switcher = hs.fnutils.partial(self.showSwitcher, self)}
  hs.spoons.bindHotkeysToSpec(def, mapping)
end

function obj:start()
  obj.logger.d("=== start")

  -- force a list rebuild when hammerspoon is restarted
  set_setting("mod_times", {})
  set_setting("app_lists", {})

  hs.application.enableSpotlightForNameSearches(false)
  self.chooserPopup = hs.chooser.new(hs.fnutils.partial(self.processSelected, self))
  self.chooserPopup:choices(hs.fnutils.partial(self.buildAppList, self))
end

return obj
