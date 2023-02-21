# FuzzySwitcher.spoon

Live in the terminal and Spotlight too heavy for simple Application startup?

Spotlight indexing every single file creepy too much?

Fed up with `cmd+tab` constantly just to hit that right icon in a looong list?

This is a minimalist replacement that fuzzy selects both running and
not-yet-running Applications enabled by the amazing
<http://www.hammerspoon.org/>

## Installation

In `~/.hammerspoon/init.lua`:

```
hs.loadSpoon("FuzzySwitcher")
spoon.FuzzySwitcher:bindHotkeys({show_switcher = {{"cmd"}, "space"}})
spoon.FuzzySwitcher:start()
```

## Usage

Fuzzy is a bit of a white lie actually: it's fuzzy with "exact match"
(`fzf -e`), which was considered less overwhelming for this use case.

Here's the difference when entering `fi`:
```
# fuzzy
Safari
FaceTime
Firefox
FindMy

# fuzzy with exact match
Firefox
FindMy
```

While there are shortcuts to select a candidate quickly from the result list,
the user is encouraged to come up with unique bits of Application names to
naturally narrow down the result to exactly one. For example on my system
`<cmd+space>ox<Enter>` will always run, or switch to a running Firefox.

## Configuration

- `obj.app_folders`: folders to watch, by default `/Applications`,
  `/System/Applications` and `~/Applications`
- `obj.app_ignore_list`: list of applications to ignore, e.g. `Siri`

## Disabling Spotlight

To hijack `cmd+space` with hammerspoon, disabling the spotlight keyboard
shortcut is not enough, it must be changed first to something else under
"Keyboard Shortcuts".

Spotlight indexing must be turned off for every volume individually, e.g.
`sudo mdutil -i off /`
