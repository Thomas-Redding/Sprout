import json

class Launcher:

    def __init__(self, spr, keyCode, cmd, opt, ctrl, shift):
        self.spr = spr
        self.ypos = 100
        self.width = 500
        self.maxHeight = 500
        self._window = self.spr.makeWindow()
        self._window.setVisible(False)
        self.setFrameForHeight(40)
        self._window.setTitle(None)
        self._window.onMessage = lambda requestStr : self.server(requestStr)
        self._window.didResignMain = lambda: self._window.setVisible(False)
        self._window.setIndexPath('~/proj/Sprout/Plugins/Launcher/index.html')
        self._window.setSpaceBehavior(1)
        self.spr.listenForHotkey(keyCode, cmd, opt, ctrl, shift, lambda a, b, c, d, e : self.toggleWindowHide())
        self.plugins = []
        self._userInput = None
        self._results = [] # (key, priority, displayHTML)
        self._resultsChanged()
        self._actionCount = 0
        self.mostRecentUpdateId = 0

    def toggleWindowHide(self):
        isVisible = self._window.visible()
        if isVisible:
            self._window.sendMessage('clear')
            self._window.returnOwnership()
        else:
            self._window.borrowOwnership()
            self.setFrameForHeight(self._height)

    def server(self, requestStr):
        tabIndex = requestStr.find('\t')
        if tabIndex == -1: tabIndex = len(requestStr)
        command = requestStr[0:tabIndex]
        commandArgs = requestStr[tabIndex+1:]
        if command == 'query':
            self.mostRecentUpdateId += 1
            self._userInput = commandArgs
            self._results = []
            self._resultsChanged()
            updateId = self.mostRecentUpdateId
            for plugin in self.plugins:
                plugin.query(commandArgs, lambda results: self.queryCallback(updateId, results))
        elif command == 'resize':
            self.setFrameForHeight(int(commandArgs))
        elif command == 'submit':
            tabIndex = commandArgs.index('\t')
            hotkeys = commandArgs[0:tabIndex]
            submitKey = commandArgs[tabIndex+1:]
            self.toggleWindowHide()
            for plugin in self.plugins:
                didUse = plugin.action(submitKey, hotkeys[0] != '0', hotkeys[1] != '0', hotkeys[2] != '0', hotkeys[3] != '0')
                if didUse: return None
            self._actionCount += 1
        elif command == 'print':
            s = self.spr.print('###' + submitKey)

    def setFrameForHeight(self, height):
        if height > self.maxHeight: height = self.maxHeight
        self._height = height
        self._window.setFrame((1680/2-self.width/2, 900-100-height, self.width, height))

    def queryCallback(self, updateId, results):
        if updateId != self.mostRecentUpdateId: return None
        self._results += results
        self._resultsChanged()

    def _resultsChanged(self):
        # Sort by priority.
        rtn = []
        for i in range(len(self._results)):
            p = self._results[i][1]
            rtn.append([self._results[i][0], p, self._results[i][2]])
        rtn = sorted(rtn, key=lambda item: -item[1])
        resultsToSend = list(map(lambda x : {'value': x[0], 'html': x[2]}, rtn))
        self._window.sendMessage('suggestions\t' + json.dumps(resultsToSend))
