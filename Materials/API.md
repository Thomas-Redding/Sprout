# APIs
## Python API
All methods are synchronous (blocking) unless marked with "(async)". In terms of future development, it should be quite easy to switch methods between synchronous and asynchronous.
### Supported
```python
class Window:
  windowId(): str
  close() # (async)
  key(): bool
  makeKey()
  makeKeyAndFront()
  # A string given here is passed to the JavaScript function spr.receive().
  sendMessage(str message) # (async)
  
  # Callbacks
  function onLoad()               # Called when the webpage loads.
  function onMessage(str message) # The string comes from the JavaScript method spr.send().
  function didBecomeMain()        # Called when the window becomes "main" status.
  function didResignMain()        # Called when the window resigns "main" status.
  
  # Path to HTML source.
  indexPath(): str
  setIndexPath(str pathToIndex) # (async)
  
  # This lets a window become key and front and then return focus to where it was originally.
  borrowOwnership()
  returnOwnership()
  
  # Everything Below this point is a "property". It has a getter and setter method.
  # e.g. '[float] frame' means there is getter, frame(), and a setter, setFrame().
  [float] frame() # From the lower left corner: [x, y, width, height]
  str title
  bool visible
  float alpha
  [float] minSize # [width, height]
  [float] maxSize # [width, height]
  bool movable
  bool supportsUserActions
  bool inDesktop     # Whether this window should appear beneath file icons.
  int spaceBehavior  # 0 = Normal Window; 1 = All Spaces; 2 = ??
  int exposeBehavior # 0 = Managed; 1 = Transient; 2 = Stationary
  # Whether this window participates in the "Cycle Through Windows Window menu item"
  bool participatesInCycle

class Sprout:
  makeWindow(): Window
  moveWindow(str windowNumber, x, y, width, height)
  activeApps(): [(str, str)] # (bundle identifiers, app name)
  mousePosition(): [float] # From the lower left corner: [x, y]
  runAppleScriptAtPath(str script)
  
  # Async methods
  print(str s) # Print to Sprout's console.
  # For keyCodes, see https://stackoverflow.com/a/16125341 or
  # https://eastmanreference.com/complete-list-of-applescript-key-codes
  listenForHotkey(self, int keyCode, bool cmd, bool opt, bool ctrl, bool shift, function callback) # (async)
  listenForMouseButtons(function callbac)
  listenForMouseMove(function callbac)
  listenForWindowMove(function callback)
  quitSprout()
  quitApp(str appName)
  forceQuitApp(str appName)
  sleepScreen():
  shutDown():
  restart():
  logOut():
  doLater(float waitTime, function callback)
  repeat(float waitTime, function callback): string # returns a unique timerId
  stopRepeat(string timerId, function callback)
  searchFiles(str mdfindQuery, [str] scopes, [(str, bool)]sortKeys, function callback, int maxResults)

spr = Sprout()
```

### Planned
```
class MenuBarItem:
  ...

class Sprout:
  makeMenubar(): MenuBarItem
```

I'm also hoping to allow Windows to be placed on the Desktop (below all other windows) and above all other windows. (Note to self: look at `NSWindowLevel` and `kCGDesktopWindowLevel`).

## JavaScript API
You can import CSS and JavaScript files from the file system as normal.
```javascript
spr.send(string message)
spr.receive(string message)
```

## Permissions

An important detail to be aware of when using Sprout is all your Python scripts get the same permissions as Sprout itself. This simplifies development, but means plugins you add from other sources have a lot of power over your system. This is an intentional decision, but has drawbacks.

A related issue is that Apple's recent sandboxing logic requires Sprout to [request automation permission from each app individually](https://www.felix-schwarz.org/blog/2018/08/new-apple-event-apis-in-macos-mojave). This is one of the justifications for a ~~simplified~~ unified privacy model: asking for permissions once per app instead of once per app-script combo dramatically simplifies user interactions.

Accessibility permission, however, is only asked for once.