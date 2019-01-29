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
  func onLoad                 # Called when the page loads.
  func onMessage(str message) # The string comes from the JavaScript method spr.send().
  
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
  listenForHotkey(self, int keyCode, bool cmd, bool opt, bool ctrl, bool shift, function callback) # (async)
  makeWindow(): Window
  print(str s) # (async) Print to Sprout's console.
  def quit() # (async) Quit Sprout.
  activeApps(): [str] # The bundle identifiers of the currently active apps.
  mousePosition(): [float] # From the lower left corner: [x, y]
  searchFiles(int maxResults, bool descendSubdirs, bool searchHidden, bool excludeDirs, bool excludeFiles, bool extensions,
      str path, function callback) # (async)

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
  makeMenubar(): MenuBarItem # (async)
  runAppleScriptAtPath(str pathToScript)
  listenForMouseButtonEvent(float x, float y, MoustButtonEventType type, function callback) # (async)
  listenForMouseMoveEvent(float x, float y, bool isLeftButtonDown, bool isRightButtonDown, bool isOtherButtonDown) # (async)
  listenForWindowDrag(function callback) # (async)
  quitApp(str appName) # (async)
  forceQuitApp(str appName) # (async)
  sleep() # (async)
  shutDown() # (async)
  callAfterDelay(float delay, function callback) # (async)
```

I'm also hoping to allow Windows to be placed on the Desktop (below all other windows) and above all other windows. (Note to self: look at `NSWindowLevel` and `kCGDesktopWindowLevel`).

## JavaScript API
You can import CSS and JavaScript files from the file system as normal.
```javascript
spr.send(string message)
spr.receive(string message)
```
