# Python API
```
class Window:
  windowId() -> str
  setIndexPath(str pathToIndex) # async
  indexPath() -> str
  setFrame([float] newFrame)
  frame() -> [float]
  sendMessage(str message) # async
  close() # async

class Sprout:
  listenForHotkey(self, keyCode, cmd, opt, ctrl, shift, callback) # async
  makeWindow() -> Window
  print(str s) # async
  def quit() # async

spr = Sprout()
```

# JavaScript API
```
spr.send(string message)
spr.receive(string message)
```
