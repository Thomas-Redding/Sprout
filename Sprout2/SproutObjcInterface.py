import os
import random
import subprocess
import string
import sys



class Helper:
    def __init__(self):
        self._uniqueId = 0
    def generateUniqueId(self):
        # ''.join(random.choices(string.ascii_letters + string.digits, k=16))
        self._uniqueId += 1
        return str(self._uniqueId)
    def finder(self, s, c):
        index = s.find(c)
        return len(s) if index == -1 else index
helper = Helper()



class ServerAPI:
    def __init__(self, praserCallback, unexpectedMessageCallback):
        self._queue = []
        self._callbacks = {}
        self._praserCallback = praserCallback
        self._unexpectedMessageCallback = unexpectedMessageCallback

    def _pipe(self, message):
        uniqueId = helper.generateUniqueId()
        message = self._escapeNewlines(message)
        sys.stdout.write(uniqueId + '\t' + message  + '\n\n')
        sys.stdout.flush()
        return uniqueId
    
    # string message : The message to send to the server.
    # string return  : The message returned by the server.
    def sendSynchronousMessage(self, message):
        self.checkQueue()
        uniqueId = self._pipe(message)
        queue = []
        for line in sys.stdin:
            s = line[:-1]
            spaceIndex = helper.finder(s, '\t')
            if s[0:spaceIndex] == uniqueId:
                return self._praserCallback(s[spaceIndex+1:])
            else:
                self._queue.append(line)

    # string   message         : The message to send to the server.
    # function responseHandler : The callback function
    # string   return          : The message returned by the server.
    def sendAsynchronousMessage(self, message, callback, debug=True):
        if debug: self.checkQueue()
        uniqueId = self._pipe(message)
        self._callbacks[uniqueId] = callback

    def _escapeNewlines(self, message):
        return message.replace('\\', '\\\\').replace('\n', '\\n')

    def _unescapeNewlines(self, message):
        state = 0
        rtn = ''
        for c in message:
            if state == 0:
                if c == '\\': state = 1
                else: rtn += c
            else:
                if c == '\\': rtn += '\\'
                elif c == "n": rtn += "\n"
                else:
                    print('ERROR in unescapeNewlines', message)
                    sys.exit(1)
                state = 0
        return rtn
    
    def _respondToStandardInput(self, message):
        message = self._unescapeNewlines(message[0:-1])
        spaceIndex = helper.finder(message, '\t')
        uniqueId = message[0:spaceIndex]
        commandAndArgs = message[spaceIndex+1:]
        if uniqueId in self._callbacks:
            parsedResponse = self._praserCallback(commandAndArgs)
            func = self._callbacks[uniqueId]
            if commandAndArgs[0:7] == 'doLater' or commandAndArgs[0:6] == 'repeat' or commandAndArgs[0:10] == 'stopRepeat':
                func()
            else:
                func(parsedResponse)
            if commandAndArgs[0:6] != 'repeat':
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
        self._windowId = helper.generateUniqueId()
        self._spr = spr
        self.onLoad = lambda:None
        self.onMessage = lambda:None
        self.didBecomeMain = lambda:None
        self.didResignMain = lambda:None
        self._indexPath = None
    def windowId(self):
        return self._windowId
    def indexPath(self):
        if not self._windowId: return None
        return self._indexPath
    def setIndexPath(self, pathToIndex):
        if not self._windowId: return None
        self._indexPath = pathToIndex
        message = 'window.setIndexPath\t' + self._windowId + '\t' + pathToIndex
        self._spr._server.sendSynchronousMessage(message)
    def frame(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getFrame\t' + self._windowId)
    def setFrame(self, newFrame):
        if not self._windowId: return None
        message = 'window.setFrame'
        message += '\t' + self._windowId
        message += '\t' + str(float(newFrame[0]))
        message += '\t' + str(float(newFrame[1]))
        message += '\t' + str(float(newFrame[2]))
        message += '\t' + str(float(newFrame[3]))
        return self._spr._server.sendSynchronousMessage(message)
    def visible(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getVisible\t' + self._windowId)
    def setVisible(self, newVisible):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.setVisible\t' + self._windowId + '\t' + ('1' if newVisible else '0'))
    def title(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getTitle\t' + self._windowId)
    def setTitle(self, newTitle):
        if not self._windowId: return None
        if newTitle == None:
            return self._spr._server.sendSynchronousMessage('window.setTitle\t' + self._windowId + '\t0\t')
        else:
            return self._spr._server.sendSynchronousMessage('window.setTitle\t' + self._windowId + '\t1\t' + newTitle)
    def alpha(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getAlpha\t' + self._windowId)
    def setAlpha(self, newAlpha):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.setAlpha\t' + self._windowId + '\t' + str(newAlpha))
    def minSize(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getMinSize\t' + self._windowId)
    def setMinSize(self, newSize):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.setMinSize\t' + self._windowId + '\t' + str(newSize[0]) + '\t' + str(newSize[1]))
    def maxSize(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getMaxSize\t' + self._windowId)
    def setMaxSize(self, newSize):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.setMaxSize\t' + self._windowId + '\t' + str(newSize[0]) + '\t' + str(newSize[1]))
    def movable(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getMovable\t' + self._windowId)
    def setMovable(self, newMovable):
        if not self._windowId: return None
        if newMovable:
            return self._spr._server.sendSynchronousMessage('window.setMovable\t' + self._windowId + '\t1')
        else:
            return self._spr._server.sendSynchronousMessage('window.setMovable\t' + self._windowId + '\t0')
    def supportsUserActions(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getSupportsUserActions\t' + self._windowId)
    def setSupportsUserActions(self, newValue):
        if not self._windowId: return None
        if newValue:
            return self._spr._server.sendSynchronousMessage('window.setSupportsUserActions\t' + self._windowId + '\t1')
        else:
            return self._spr._server.sendSynchronousMessage('window.setSupportsUserActions\t' + self._windowId + '\t0')
    def inDesktop(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getInDesktop\t' + self._windowId)
    def setInDesktop(self, newValue):
        if not self._windowId: return None
        if newValue:
            return self._spr._server.sendSynchronousMessage('window.setInDesktop\t' + self._windowId + '\t1')
        else:
            return self._spr._server.sendSynchronousMessage('window.setInDesktop\t' + self._windowId + '\t0')
    # 0 = Normal Window; 1 = Window on all spaces (like menu bar); 2 = When the window becomes active
    def getSpaceBehavior(self):
        if not self._windowId: return None
        bitmask = self._spr._server.sendSynchronousMessage('window.getCollectionBehavior\t' + self._windowId)
        if bitmask & 1: return 1
        if bitmask & 2: return 2
        else: return 0
    def setSpaceBehavior(self, newValue):
        if not self._windowId: return None
        if type(newValue) != int:
            raise Exception('window.spaceBehavior must be an integer.')
        if newValue < 0 or 2 < newValue:
            raise Exception('window.spaceBehavior must be 0, 1 or 2.')
        bitmask = self._spr._server.sendSynchronousMessage('window.getCollectionBehavior\t' + self._windowId)
        if newValue == 0:
            bitmask &= ~1
            bitmask &= ~2
        elif newValue == 1:
            bitmask |= 1
            bitmask &= ~2
        else:
            bitmask &= ~1
            bitmask |= 2
        self._spr._server.sendSynchronousMessage('window.setCollectionBehavior\t' + self._windowId + '\t' + str(bitmask))
    # 0 = Managed; 1 = Transient; 2 = Stationary
    def getExposeBehavior(self):
        if not self._windowId: return None
        if bitmask & 4: return 0
        if bitmask & 8: return 1
        if bitmask & 16: return 2
        raise Exception('window.getExposeBehavior() exception')
    def setExposeBehavior(self, newValue):
        if not self._windowId: return None
        if type(newValue) != int:
            raise Exception('window.exposeBehavior must be an integer.')
        if newValue < 0 or 2 < newValue:
            raise Exception('window.exposeBehavior must be 0, 1 or 2.')
        bitmask = self._spr._server.sendSynchronousMessage('window.getCollectionBehavior\t' + self._windowId)
        if newValue == 0:
            bitmask |= 4
            bitmask &= ~8
            bitmask &= ~16
        elif newValue == 1:
            bitmask &= ~4
            bitmask |= 8
            bitmask &= ~16
        else:
            bitmask &= ~4
            bitmask &= ~8
            bitmask |= 16
        self._spr._server.sendSynchronousMessage('window.setCollectionBehavior\t' + self._windowId + '\t' + str(bitmask))
    def participatesInCycle(self):
        if not self._windowId: return None
        bitmask = self._spr._server.sendSynchronousMessage('window.getCollectionBehavior\t' + self._windowId)
        return bool(bitmask & 32)
    def setParticipatesInCycle(self, newValue):
        if not self._windowId: return None
        if type(newValue) != int:
            raise Exception('window.cycleBehavior must be an integer.')
        if newValue < 0 or 2 < newValue:
            raise Exception('window.cycleBehavior must be 0 or 1.')
        bitmask = self._spr._server.sendSynchronousMessage('window.getCollectionBehavior\t' + self._windowId)
        if newValue:
            bitmask |= 32
            bitmask &= ~64
        else:
            bitmask &= ~32
            bitmask |= 64
        self._spr._server.sendSynchronousMessage('window.setCollectionBehavior\t' + self._windowId + '\t' + str(bitmask))
    def isKey(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.getKey\t' + self._windowId)
    def makeKey(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.makeKey\t' + self._windowId)
    def makeKeyAndFront(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.makeKeyAndFront\t' + self._windowId)
    def borrowOwnership(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.borrowOwnership\t' + self._windowId)
    def returnOwnership(self):
        if not self._windowId: return None
        return self._spr._server.sendSynchronousMessage('window.returnOwnership\t' + self._windowId)
    def sendMessage(self, message):
        self._spr._server.sendAsynchronousMessage('window.sendMessage\t' + self._windowId + '\t' + message, lambda x : x)
    def close(self):
        self._spr._server.sendAsynchronousMessage('window.close\t' + self._windowId, lambda x : x)
        self._windowId = None

class LiteWindow:
    def __init__(self, spr, windowNumber, bundleIdentifier, appName):
        self._spr = spr
        self._number = windowNumber
        self._bundleIdentifier = bundleIdentifier
        self._appName = appName
    def number(self): return self._number
    def setNumber(self, newVal): self._number = newVal
    def bundleIdentifier(self): return self._bundleIdentifier
    def setBundleIdentifier(self, newVal): self._bundleIdentifier = newVal
    def appName(self): return self._appName
    def setAppName(self, newVal): self._appName = newVal

class Sprout:
    def __init__(self):
        self._server = ServerAPI(lambda message : self.parseResponse(message),
                                 lambda message : self.unexpectedMessageCallback(message))
        self._windows = {}
        self.shared = {}
        self._hotkeyCallbacks = {}
        self._mouseButtonCallbacks = []
        self._mouseMoveCallbacks = []
        self._windowMovedCallbacks = []

    # For keyCodes, see https://stackoverflow.com/a/16125341 or https://eastmanreference.com/complete-list-of-applescript-key-codes.
    def listenForHotkey(self, keyCode, cmd, opt, ctrl, shift, callback):
        x = self._hotkeyStr(keyCode, cmd, opt, ctrl, shift)
        if x not in self._hotkeyCallbacks: self._hotkeyCallbacks[x] = []
        self._hotkeyCallbacks[x].append(callback)
        self._server.sendAsynchronousMessage('registerHotKey\t' + x, lambda x : x)

    def listenForMouseButtons(self, callback):
        self._mouseButtonCallbacks.append(callback)
    
    def listenForMouseMove(self, callback):
        self._mouseMoveCallbacks.append(callback)
    
    def listenForWindowMove(self, callback):
        self._windowMovedCallbacks.append(callback)

    def _hotkeyStr(self, keyCode, cmd, opt, ctrl, shift):
        rtn = str(keyCode)
        rtn += '\t'
        rtn += '1' if cmd else '0'
        rtn += '1' if opt else '0'
        rtn += '1' if ctrl else '0'
        rtn += '1' if shift else '0'
        return rtn

    def _mouseButtonStr(self, button, goingDown):
        rtn = ''
        if button == 1: rtn += 'L'
        elif button == -1: rtn += 'R'
        elif button == 0: rtn += 'O'
        rtn += '1' if goingDown else '0'
        return rtn

    def makeWindow(self):
        rtn = Window(self)
        self._windows[rtn.windowId()] = rtn
        response = self._server.sendSynchronousMessage('makeWindow\t' + rtn.windowId())
        return rtn

    def print(self, s):
        self._server.sendAsynchronousMessage('print\t' + s, lambda x : x, False)
    
    def quitSprout(self):
        self._server.sendAsynchronousMessage('quitSprout', lambda x : x)

    def runningApps(self):
        return self._server.sendSynchronousMessage('runningApps')

    def frontmostApp(self):
        return self._server.sendSynchronousMessage('frontmostApp')
    
    def quitApp(self, bundleIdentifier):
        self._server.sendAsynchronousMessage('quitApp\t' + bundleIdentifier, lambda x: x)
    
    def forceQuitApp(self, bundleIdentifier):
        self._server.sendAsynchronousMessage('forceQuitApp\t' + bundleIdentifier, lambda x: x)
    
    def sleepScreen(self):
        self._server.sendAsynchronousMessage('power.sleepScreen', lambda x: x)
    def shutDown(self):
        self._server.sendAsynchronousMessage('power.shutDown', lambda x: x)
    def restart(self):
        self._server.sendAsynchronousMessage('power.restart', lambda x: x)
    def logOut(self):
        self._server.sendAsynchronousMessage('power.logOut', lambda x: x)
    
    def runAppleScript(self, script):
        # Note: Bash strings denoted by single quotes can't contain single quotes (even if they're "escaped").
        # That's why we use double quotes.
        return self._server.sendSynchronousMessage('runAppleScript\t' + script)

    def mousePosition(self):
        return self._server.sendSynchronousMessage('mousePosition')
    
    def moveWindow(self, liteWindow, x, y, width, height):
        message = 'liteWindow.moveWindow'
        message += '\t' + str(liteWindow.number())
        message += '\t' + str(x)
        message += '\t' + str(y)
        message += '\t' + str(width)
        message += '\t' + str(height)
        return self._server.sendSynchronousMessage(message)
    
    def getFrontmostWindowFrame(self):
        return self._server.sendSynchronousMessage('getFrontmostWindowFrame')
    
    def setFrontmostWindowFrame(self, newFrame):
        message = 'setFrontmostWindowFrame'
        message += '\t' + str(newFrame[0])
        message += '\t' + str(newFrame[1])
        message += '\t' + str(newFrame[2])
        message += '\t' + str(newFrame[3])
        return self._server.sendSynchronousMessage(message)
    
    def getClipboard(self):
        return self._server.sendSynchronousMessage('getClipboard')
    def setClipboard(self, s):
        return self._server.sendSynchronousMessage('setClipboard\t' + s)
    
    def define(self, word):
        message = 'define\t' + word;
        return self._server.sendSynchronousMessage(message)
    
    def doLater(self, waitTime, callback):
        self._server.sendAsynchronousMessage('doLater\t' + str(waitTime), callback)

    def repeat(self, waitTime, callback):
        timerId = helper.generateUniqueId()
        self._server.sendAsynchronousMessage('repeat\t' + timerId + '\t' + str(waitTime), callback)
        return timerId

    def stopRepeat(self, timerId, callback=None):
        if callback:
            self._server.sendAsynchronousMessage('stopRepeat\t' + timerId, callback)
        else:
            self._server.sendAsynchronousMessage('stopRepeat\t' + timerId, lambda:None)

    def screenFrames(self):
        return self._server.sendSynchronousMessage('screenFrames')

    def parseResponse(self, message):
        command = self.commandFromLine(message)
        argStr = message[len(command)+1:]
        if command == 'runAppleScript':
            result = self.argArrayFromArgStr(argStr, 1)
            return result[0]
        elif command == 'registerHotKey':
            None
        elif command == 'hotKeyPressed':
            keyCode, flags = self.argArrayFromArgStr(argStr, 2)
            cmd = (flags[0] != '0')
            opt = (flags[1] != '0')
            ctrl = (flags[2] != '0')
            shift = (flags[3] != '0')
            return (argStr, keyCode, cmd, opt, ctrl, shift)
        elif command == 'searchFiles':
            return argStr.split('\t')
        elif command == 'runningApps':
            apps = argStr[0:-1].split('/')
            for i in range(len(apps)):
                firstSpace = helper.finder(apps[i], ' ')
                apps[i] = (apps[i][:firstSpace], apps[i][firstSpace+1:])
            return apps[1:]
        elif command == 'frontmostApp':
            bundleId, appName = self.argArrayFromArgStr(argStr[:-1], 2)
            return (bundleId, appName)
        elif command == 'power.sleepScreen' or command == 'power.shutDown' or command == 'power.restart' or command == 'power.logOut':
            None
        elif command == 'mousePosition':
            x, y = self.argArrayFromArgStr(argStr, 2)
            return (float(x), float(y))
        elif command == 'doLater' or command == 'repeat' or command == 'stopRepeat':
            None
        elif command == 'liteWindow.windowMoved':
            windowNumber, bundleIdentifier, appName = self.argArrayFromArgStr(argStr, 3)
            return LiteWindow(self, windowNumber, bundleIdentifier, appName)
        elif command == 'liteWindow.moveWindow':
            return None
        elif command == 'getFrontmostWindowFrame' or command == 'setFrontmostWindowFrame':
            x, y, w, h = self.argArrayFromArgStr(argStr, 4)
            return [float(x), float(y), float(w), float(h)]
        elif command == 'getClipboard' or command == 'setClipboard':
            arr = self.argArrayFromArgStr(argStr, 1)
            return arr[0]
        elif command == 'makeWindow':
            return None
        elif command == 'screenFrames':
            frameStrings = argStr.split('\t')
            frames = []
            for frameString in frameStrings:
                frames.append(frameString.split(' '))
            for i in range(len(frames)):
                frames[i][0] = float(frames[i][0])
                frames[i][1] = float(frames[i][1])
                frames[i][2] = float(frames[i][2])
                frames[i][3] = float(frames[i][3])
            return frames
        elif command == 'define':
            argsLeft = argStr
            args = []
            while True:
                index = argsLeft.find('\t')
                if index == -1: break
                args.append(argsLeft[0:index])
                argsLeft = argsLeft[index + 1:]
            args.append(argsLeft)
            rtn = []
            for i in range(0, len(args), 2):
                rtn.append([args[i], args[i+1]])
            return rtn
        elif command == 'window.setFrame' or command == 'window.getFrame':
            windowId, x, y, w, h = self.argArrayFromArgStr(argStr, 5)
            x = float(x)
            y = float(y)
            w = float(w)
            h = float(h)
            return (x, y, w, h)
        elif command == 'window.setVisible' or command == 'window.getVisible':
            windowId, isVisible = self.argArrayFromArgStr(argStr, 2)
            return bool(int(isVisible))
        elif command == 'window.getTitle' or command == 'window.setTitle':
            windowId, isTitleVisible, titleStr = self.argArrayFromArgStr(argStr, 3)
            isTitleVisible = bool(int(isTitleVisible))
            if not isTitleVisible: return None
            else: return titleStr
        elif command == 'window.getAlpha' or command == 'window.setAlpha':
            windowId, isVisible = self.argArrayFromArgStr(argStr, 2)
            return bool(int(isVisible))
        elif command == 'window.getMinSize' or command == 'window.setMinSize':
            windowId, isVisible = self.argArrayFromArgStr(argStr, 2)
            return bool(int(isVisible))
        elif command == 'window.getMaxSize' or command == 'window.setMaxSize':
            windowId, isVisible = self.argArrayFromArgStr(argStr, 2)
            return bool(int(isVisible))
        elif command == 'window.getMovable' or command == 'window.setMovable':
            windowId, isMovable = self.argArrayFromArgStr(argStr, 2)
            return bool(int(isMovable))
        elif command == 'window.setIndexPath':
            None
        elif command == 'window.didLoad':
            return self.argArrayFromArgStr(argStr, 1)[0]
        elif command == 'window.close':
            None
        elif command == 'window.makeKeyAndFront':
            None
        elif command == 'mouseButton':
            button, goingDown = self.argArrayFromArgStr(argStr, 2)
            if goingDown == 'down': goingDown = True
            elif goingDown == 'up': goingDown = False
            return (int(button), goingDown)
        elif command == 'mouseMove':
            return int(self.argArrayFromArgStr(argStr, 1)[0])
        elif command == 'window.sendMessage':
            return None
        elif command == 'window.request':
            windowId, message = self.argArrayFromArgStr(argStr, 2)
            return (windowId, message)
        elif command == 'window.borrowOwnership' or command == 'window.returnOwnership':
            None
        elif command == 'window.didBecomeMain' or command == 'window.didResignMain':
            windowId = self.argArrayFromArgStr(argStr, 1)[0]
            return windowId
        elif command == 'window.getSupportsUserActions' or command == 'window.setSupportsUserActions':
            windowId, value = self.argArrayFromArgStr(argStr, 2)
            return value
        elif command == 'window.getInDesktop' or command == 'window.setInDesktop':
            windowId, value = self.argArrayFromArgStr(argStr, 2)
            return bool(value)
        elif command == 'window.getCollectionBehavior' or command == 'window.setCollectionBehavior':
             windowId, value = self.argArrayFromArgStr(argStr, 2)
             return int(value)
        elif command == 'window.getIsWidget' or command == 'window.setIsWidget':
            windowId, value = self.argArrayFromArgStr(argStr, 2)
            return value
        else:
            self.print('UNKNOWN COMMAND: ' + message)

    def unexpectedMessageCallback(self, message):
        command = self.commandFromLine(message)
        parsedMessage = self.parseResponse(message)
        if command == 'window.didLoad':
            self._windows[parsedMessage].onLoad()
        elif command == 'window.request':
            windowId, message = parsedMessage
            self._windows[windowId].onMessage(message)
        elif command == 'hotKeyPressed':
            hotKeyCode, keyCode, cmd, opt, ctrl, shift = parsedMessage
            callbacks = self._hotkeyCallbacks[hotKeyCode]
            for callback in callbacks:
                callback(int(keyCode), cmd, opt, ctrl, shift)
        elif command == 'mouseButton':
            button, goingDown = parsedMessage
            for callback in self._mouseButtonCallbacks:
                callback(button, goingDown)
        elif command == 'mouseMove':
            button = parsedMessage
            for callback in self._mouseMoveCallbacks:
                callback(button)
        elif command == 'liteWindow.windowMoved':
            for callback in self._windowMovedCallbacks:
                callback(parsedMessage)
        elif command == 'window.didBecomeMain':
            windowId = parsedMessage
            self._windows[parsedMessage].didBecomeMain()
        elif command == 'window.didResignMain':
            windowId = parsedMessage
            self._windows[parsedMessage].didResignMain()
        else:
            self.print('Unknown UnexpectedMessageCallback: ' + message)
        # TODO: Use parsed message.
        
    def commandFromLine(self, line):
        index = line.find('\t')
        if index == -1: return line
        else: return line[0:index]

    def argArrayFromArgStr(self, argStr, maxNumArgs):
        argsLeft = argStr
        args = []
        for i in range(maxNumArgs-1):
            index = argsLeft.find('\t')
            if index == -1: break
            args.append(argsLeft[0:index])
            argsLeft = argsLeft[index + 1:]
        args.append(argsLeft)
        if len(args) != maxNumArgs: return None
        return args

    def respondToStandardInput(self, line):
        self._server.respondToStandardInput(line)

spr = Sprout()

PATH_TO_RC = '/Users/thomasredding/proj/Sprout/Plugins/rc.py'
with open(PATH_TO_RC) as rcFile:
    exec(rcFile.read(), { 'spr': spr })

for line in sys.stdin:
    spr.respondToStandardInput(line)
