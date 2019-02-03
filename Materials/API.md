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

class Sprout:
  makeWindow(): Window
  activeApps(): [(str, str)] # (bundle identifiers, app name)
  mousePosition(): [float] # From the lower left corner: [x, y]
  runAppleScriptAtPath(str script)
  
  # Async methods
  print(str s) # Print to Sprout's console.
  listenForHotkey(self, int keyCode, bool cmd, bool opt, bool ctrl, bool shift, function callback) # (async)
  listenForMouseButtons(function callbac)
  listenForMouseMove(function callbac)
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
  searchFiles(int maxResults, bool descendSubdirs, bool searchHidden, bool excludeDirs, bool excludeFiles, bool extensions,
      str path, function callback): [string]

spr = Sprout()
```

### Planned
```
class Window:
  interactable(): bool
  setInteractable(bool interactable)

class MenuBarItem:
  ...

class Sprout:
  makeMenubar(): MenuBarItem
  listenForWindowDrag(function callback) # (async)
```

I'm also hoping to allow Windows to be placed on the Desktop (below all other windows) and above all other windows. (Note to self: look at `NSWindowLevel` and `kCGDesktopWindowLevel`).

## JavaScript API
You can import CSS and JavaScript files from the file system as normal.
```javascript
spr.send(string message)
spr.receive(string message)
[function] spr.hotkeyCallbacks
```
An important thing to note is that due to limitations imposed by Apple's `WKWebView`, hot keys are not applied by default. This is a annoying because it (for example) prevents cut, copy, paste, and select all. To navigate around this problem, we provide `spr.hotkeyCallbacks`, which is an array that gets iterated through when a hotkey is pressed and the Window is in focus.

