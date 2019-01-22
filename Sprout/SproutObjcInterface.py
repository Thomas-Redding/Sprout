import select
from subprocess import Popen, PIPE
import sys
import time

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

class ObjcInterface:
  def __init__(self):
    self.widgets = {}
    self.widgetPropertyCallbacks = {}
    self.widgetServers = {}
    self.hotkeyCallbacks = {}
    self.timers = []
  
  def listenForHotkey(self, keyCode, cmd, opt, ctrl, shift, callback):
    x = self._hotkeyStr(keyCode, cmd, opt, ctrl, shift)
    self.hotkeyCallbacks[x] = callback
    sys.stdout.write('registerHotkey '+ x + '\n')
    sys.stdout.flush()

  def _hotkeyStr(self, keyCode, cmd, opt, ctrl, shift):
    rtn = str(keyCode)
    rtn += ' '
    rtn += '1' if cmd else '0'
    rtn += '1' if opt else '0'
    rtn += '1' if ctrl else '0'
    rtn += '1' if shift else '0'
    return rtn
  
  # widgetId - random string that doesn't contain whitespace.
  def makeWidgetWithId(self, widgetId, makeWidgetWithId, loadFunc):
    self.widgets[widgetId] = loadFunc
    sys.stdout.write('widget ' + widgetId + ' ' + makeWidgetWithId + '\n')
    sys.stdout.flush()
  
  def serveWidgetWithId(self, widgetId, func):
    self.widgetServers[widgetId] = func
  
  def setWidgetProperty(self, widgetId, key, value):
    sys.stdout.write('setWidgetProperty ' + widgetId + ' ' + key + ' ' + value + '\n')
    sys.stdout.flush()
  
  def doAfterLag(self, seconds, callback):
    self.timers.append((time.time() + seconds, callback))

  def getWidgetProperty(self, widgetId, key, callback):
    if (widgetId, key) not in self.widgetPropertyCallbacks:
      self.widgetPropertyCallbacks[(widgetId, key)] = []
    self.widgetPropertyCallbacks[(widgetId, key)].append(callback)
    sys.stdout.write('getWidgetProperty ' + widgetId + ' ' + key + '\n')
    sys.stdout.flush()
  
  # Call this method frequently (on the order of 30 times per second).
  # It checks whether events (e.g. hotkeys) have occured.
  def poll(self):
    # Loop while the standard input pipe has data.
    # This while-loop condition may not work on Windows.
    # See https://stackoverflow.com/a/3732001.
    t = time.time()
    for i in range(len(self.timers)):
      if self.timers[i][0] <= t:
        self.timers[i][1]()
        del self.timers[i]
    while select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], []):
      line = sys.stdin.readline()
      line = line[:-1]
      if line[0:13] == 'hotKeyPressed':
        args = line[14:]
        spaceIndex = args.index(' ')
        keyCode = int(args[0:spaceIndex])
        modifierFlags = args[spaceIndex+1:]
        cmd = (modifierFlags[0] == '1')
        opt = (modifierFlags[1] == '1')
        ctrl = (modifierFlags[2] == '1')
        shift = (modifierFlags[3] == '1')
        x = self._hotkeyStr(keyCode, cmd, opt, ctrl, shift)
        if x in self.hotkeyCallbacks:
          self.hotkeyCallbacks[x](keyCode, cmd, opt, ctrl, shift)
      elif line[0:13] == 'widgetMessage':
        args = line[14:]
        firstSpace = args.index(' ')
        widgetId = args[0:firstSpace]
        message = args[firstSpace+1:]
        if widgetId in self.widgetServers:
          self.widgetServers[widgetId](widgetId, message)
      elif line[0:13] == 'widgetDidLoad':
        widgetId = line[14:]
        if widgetId in self.widgetServers:
          self.widgets[widgetId](widgetId)
      elif line[0:17] == 'getWidgetProperty':
        args = line[18:].split(' ')
        widgetId = args[0]
        key = args[1]
        value = args[2]
        for callback in self.widgetPropertyCallbacks[(widgetId, key)]:
          callback(widgetId, key, value)
        del self.widgetPropertyCallbacks[(widgetId, key)]
      else:
        self.print('UNKNOWN COMMAND:' + line)

  # Print to Xcode console.
  def print(self, s):
    sys.stdout.write('print ' + str(s) + '\n')
    sys.stdout.flush()
  
  def sendMessageToWidget(self, widgetId, message):
    sys.stdout.write('sendMessageToWidget ' + widgetId + ' ' + message + '\n')
    sys.stdout.flush()

  def activeApplication(self):
    return (NSWorkspace.sharedWorkspace().activeApplication()['NSApplicationName'])

  # https://stackoverflow.com/a/2941735
  def runAppleScript(self, script, args):
    p = Popen(['osascript', '-'] + args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    stdout, stderr = p.communicate(script.encode('utf-8'))
    return (p.returncode, stdout.decode('utf-8'), stderr.decode('utf-8'))

  def runPython(self, script, args):
    p = Popen(['osascript', '-'] + args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    stdout, stderr = p.communicate(script.encode('utf-8'))
    return (p.returncode, stdout.decode('utf-8'), stderr.decode('utf-8'))
