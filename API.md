# Python API
All methods are synchronous (blocking) unless marked with "async". In terms of future development, it should be quite easy to switch methods between synchronous and asynchronous.
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
  listenForHotkey(self, keyCode, cmd, opt, ctrl, shift, callback) # async
  makeWindow() -> Window
  print(str s) # async
  def quit() # async

spr = Sprout()
```

# JavaScript API
You can import CSS and JavaScript files from the file system as normal.
```
spr.send(string message)
spr.receive(string message)
```
