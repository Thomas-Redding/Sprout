# APIs
## Python API
All methods are synchronous (blocking) unless marked with "async". In terms of future development, it should be quite easy to switch methods between synchronous and asynchronous.
### Supported
```
class Window:
  windowId() -> str
  # Path to HTML source.
  indexPath() -> str
  setIndexPath(str pathToIndex) # async
  # Frame of window from lower left corner.
  # [x, y, width, height]
  frame() -> [float]
  setFrame([float] newFrame)
  close() # async
  # A string given here is passed to the JavaScript function spr.receive().
  sendMessage(str message) # async
  func onLoad                 # Called when the page loads.
  func onMessage(str message) # The string comes from the JavaScript method spr.send().

class Sprout:
  listenForHotkey(self, int keyCode, bool cmd, bool opt, bool ctrl, bool shift, function callback) # async
  makeWindow() -> Window
  print(str s) # async
  def quit() # async

spr = Sprout()
```

### Planned
```
class Window:
  visible() -> bool
  setVisible(bool visible)
  # None is used to indicate the title bar should be hidden.
  title() -> str
  setTitle(str title)
  alpha() -> float
  setAlpha(float alpha)
  draggable() -> bool
  setDraggable(bool draggable)
  movable() -> bool
  setMovable(bool movable)
  interactable() -> bool
  setInteractable(bool interactable)
  minSize() -> [float]
  setMinSize([float])
  maxSize() -> [float]
  setMaxSize([float])
  key() -> bool
  makeKey()
  makeKeyAndFront()
  front() -> bool

class MenuBarItem:
  ...

class Sprout:
  makeMenubar() -> MenuBarItem # async
  runAppleScriptAtPath(str pathToScript)
  listenForMouseButtonEvent(float x, float y, MoustButtonEventType type, function callback) # async
  listenForMouseMoveEvent(float x, float y, bool isLeftButtonDown, bool isRightButtonDown, bool isOtherButtonDown) # async
  mousePosition() -> [float]
  listenForWindowDrag(function callback) # async
  activeApps() -> [str]
  quitApp(str appName) # async
  forceQuitApp(str appName) # async
  sleep() # async
  shutDown() # async
```

I'm also hoping to allow Windows to be placed on the Desktop (below all other windows) and above all other windows. (Note to self: look at `NSWindowLevel` and `kCGDesktopWindowLevel`).

## JavaScript API
You can import CSS and JavaScript files from the file system as normal.
```
spr.send(string message)
spr.receive(string message)
```
