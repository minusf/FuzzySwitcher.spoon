# FuzzySwitcher.spoon

Live in the terminal and Spotlight too heavy for simple Applications
searching? This is a minimalist replacement that fzf-selects only
Applications built on top of <http://www.hammerspoon.org/>

## Installation

In `~/.hammerspoon/init.lua`:

```
hs.loadSpoon("FuzzySwitcher")
spoon.FuzzySwitcher:bindHotkeys({show_switcher = {{"cmd"}, "space"}})
spoon.FuzzySwitcher:start()
```

## Disabling Spotlight

To hijack `cmd+space` with hammerspoon, disabling the spotlight keyboard
shortcut is not enough, it must be changed first to something else under
"Keyboard Shortcuts".

Spotlight indexing must be turned off for every volume individually, e.g.
`sudo mdutil -i off /`

## Configuration

- `obj.app_folders`: folders to watch, by default `/Applications`,
  `/System/Applications` and `~/Applications`
- `obj.app_ignore_list`: list of applications to ignore, e.g. `Siri`
