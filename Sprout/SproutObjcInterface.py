import random
import select
import string
from subprocess import Popen, PIPE
import sys

# MacOs only - requires `pip install pyobjc.`
# Might be unneccssary going forward.
from Foundation import NSBundle
from AppKit import NSWorkspace

# Update menu item from "Python" to "Sprout".
bundle = NSBundle.mainBundle()
if bundle:
  info = bundle.localizedInfoDictionary() or bundle.infoDictionary()
  if info and info['CFBundleName'] == 'Python':
    info['CFBundleName'] = 'Sprout'

# spr.listenForHotkey(49, True, False, False, False) - Listen for 'CMD + SPACE'
# spt.poll()                                         - Perform hotkey callbacks.
# spt.print("foo")                                   - Print "foo" to the Xcode terminal.
# spt.activeApplication()                            - The name of the current active application.
# spt.runAppleScript(script, args)                   - Run the given AppleScript.

def generateUniqueId():
  return ''.join(random.choices(string.ascii_letters + string.digits, k=16))

def finder(s, c):
  index = s.find(c)
  return len(s) if index == -1 else index





class ServerAPI:
  def __init__(self, praserCallback, unexpectedMessageCallback):
    self._queue = []
    self._callbacks = {}
    self._praserCallback = praserCallback
    self._unexpectedMessageCallback = unexpectedMessageCallback
  
  # string message : The message to send to the server.
  # string return  : The message returned by the server.
  def sendSynchronousMessage(self, message):
    self.checkQueue()
    uniqueId = generateUniqueId()
    sys.stdout.write(uniqueId + ' ' + message + '\n')
    sys.stdout.flush()
    queue = []
    for line in sys.stdin:
      spaceIndex = finder(line, ' ')
      if line[0:spaceIndex] == uniqueId:
        return self._praserCallback(line[spaceIndex+1:])
      else:
        self._queue.append(line)

  # string   message         : The message to send to the server.
  # function responseHandler : The callback function
  # string   return          : The message returned by the server.
  def sendAsynchronousMessage(self, message, callback, debug=True):
    if debug: self.checkQueue()
    uniqueId = generateUniqueId()
    sys.stdout.write(uniqueId + ' ' + message + '\n')
    sys.stdout.flush()
    self._callbacks[uniqueId] = callback
  
  def _respondToStandardInput(self, line):
    line = line[0:-1]
    spaceIndex = finder(line, ' ')
    uniqueId = line[0:spaceIndex]
    commandAndArgs = line[spaceIndex+1:]
    if uniqueId in self._callbacks:
      self._callbacks[uniqueId](self._praserCallback(commandAndArgs))
      del self._callbacks[uniqueId]
    else:
      self._unexpectedMessageCallback(commandAndArgs)

  def respondToStandardInput(self, line):
    self.checkQueue()
    self._respondToStandardInput(line)

  def checkQueue(self):
    queue = self._queue[:]
    self._queue = []
    for line in queue:
      self._respondToStandardInput(line)





class Window:
  def __init__(self, spr):
    self._windowId = generateUniqueId()
    self._spr = spr
    self.onCreate = None
    self.onLoad = None
    self.onMessage = None
    self._indexPath = None
  def windowId(self):
    return self._windowId
  def setIndexPath(self, pathToIndex):
    if not self._windowId: return None
    self._indexPath = pathToIndex
    message = 'window.setIndexPath ' + self._windowId + ' ' + pathToIndex
    self._spr._server.sendSynchronousMessage(message)
  def indexPath(self):
    if not self._windowId: return None
    return self._indexPath
  def setFrame(self, newFrame):
    if not self._windowId: return None
    message = 'window.setFrame'
    message += ' ' + self._windowId
    message += ' ' + str(float(newFrame[0]))
    message += ' ' + str(float(newFrame[1]))
    message += ' ' + str(float(newFrame[2]))
    message += ' ' + str(float(newFrame[3]))
    return self._spr._server.sendSynchronousMessage(message)
  def frame(self):
    if not self._windowId: return None
    return self._spr._server.sendSynchronousMessage('window.getFrame ' + self._windowId)
  def sendMessage(self, message):
    self._spr._server.sendAsynchronousMessage('window.sendMessage ' + self._windowId + ' ' + message, lambda x : x)
  def close(self):
    self._spr._server.sendAsynchronousMessage('window.close ' + self._windowId, lambda x : x)
    self._windowId = None

# ServerAPI
#   sendSynchronousMessage(string message)
#   sendAsynchronousMessage(string message, function callback)
#   _respondToStandardInput(string line)
#   respondToStandardInput(string line)



class Sprout:
  def __init__(self):
    self._server = ServerAPI(lambda message : self.parseResponse(message),
                             lambda message : self.unexpectedMessageCallback(message))
    self._windows = {}
    self._hotkeyCallbacks = {}

  def listenForHotkey(self, keyCode, cmd, opt, ctrl, shift, callback):
    x = self._hotkeyStr(keyCode, cmd, opt, ctrl, shift)
    if x not in self._hotkeyCallbacks: self._hotkeyCallbacks[x] = []
    self._hotkeyCallbacks[x].append(callback)
    self._server.sendAsynchronousMessage('registerHotKey ' + x, lambda x : x)

  def _hotkeyStr(self, keyCode, cmd, opt, ctrl, shift):
    rtn = str(keyCode)
    rtn += ' '
    rtn += '1' if cmd else '0'
    rtn += '1' if opt else '0'
    rtn += '1' if ctrl else '0'
    rtn += '1' if shift else '0'
    return rtn

  def makeWindow(self):
    rtn = Window(self)
    self._windows[rtn.windowId()] = rtn
    response = self._server.sendSynchronousMessage('makeWindow ' + rtn.windowId())
    return rtn

  def print(self, s):
    self._server.sendAsynchronousMessage('print ' + s, lambda x : x, False)
  
  def quit(self):
    self._server.sendAsynchronousMessage('quit', lambda x : x)
  
  def parseResponse(self, message):
    command = self.commandFromLine(message)
    argStr = message[len(command)+1:]
    if command == 'registerHotKey':
      None
    elif command == 'makeWindow':
      None
    elif command == 'window.setFrame' or command == 'window.getFrame':
      windowId, x, y, w, h = self.argArrayFromArgStr(argStr, 5)
      x = float(x)
      y = float(y)
      w = float(w)
      h = float(h)
      return [x, y, w, h]
    elif command == 'window.setIndexPath':
      None
    elif command == 'window.didLoad':
      return self.argArrayFromArgStr(argStr, 1)[0]
    elif command == 'window.close':
      None
    elif command == 'hotKeyPressed':
      hotKeyCode = self.argArrayFromArgStr(argStr, 1)[0]
      if hotKeyCode in self._hotkeyCallbacks:
        keyCode, flags = self.argArrayFromArgStr(argStr, 2)
        callbacks = self._hotkeyCallbacks[hotKeyCode]
        for callback in callbacks:
          callback(int(keyCode), int(flags[0]), int(flags[1]), int(flags[2]), int(flags[3]))
    elif command == 'window.sendMessage':
      None
    elif command == 'window.request':
      windowId, message = self.argArrayFromArgStr(argStr, 5)
      return (windowId, message)
    else:
      self.print('UNKNOWN COMMAND: ' + message)

  def unexpectedMessageCallback(self, message):
    command = self.commandFromLine(message)
    parsedMessage = self.parseResponse(message)
    if command == 'window.didLoad':
      self._windows[parsedMessage].onLoad()
    elif command == 'window.request':
      windowId, message = parsedMessage
      self._windows[parsedMessage].onMessage(message)
    else:
      self.print('Unknown UnexpectedMessageCallback: ' + message)
    # TODO: Use parsed message.
    
  def commandFromLine(self, line):
    index = line.find(' ')
    if index == -1: return line
    else: return line[0:index]

  def argArrayFromArgStr(self, argStr, maxNumArgs):
    argsLeft = argStr
    args = []
    for i in range(maxNumArgs-1):
      index = argsLeft.find(' ')
      if index == -1: break
      args.append(argsLeft[0:index])
      argsLeft = argsLeft[index + 1:]
    args.append(argsLeft)
    if len(args) != maxNumArgs: return None
    return args

  def respondToStandardInput(self, line):
    self._server.respondToStandardInput(line)

spr = Sprout()


PATH_TO_RC = '/Users/thomasredding/Library/Developer/Xcode/DerivedData/Sprout-hjjqxrkrofbtmobzhtbjvdwdspju/Build/Products/Debug/Sprout.app/Contents/Resources/main-sprout.py'
with open(PATH_TO_RC) as rcFile:
  exec(rcFile.read(), { 'spr': spr })


for line in sys.stdin:
  spr.respondToStandardInput(line)
