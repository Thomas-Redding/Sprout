import json

class Launcher:

    def __init__(self, spr):
        self.spr = spr
        self._window = self.spr.makeWindow()
        self._window.setVisible(False)
        self._window.setFrame([100, 100, 500, 500])
        self._window.setTitle(None)
        self._window.onMessage = lambda requestStr : self.server(requestStr)
        self._window.didResignMain = lambda: self._window.setVisible(False)
        self._window.setIndexPath('~/Projects/Sprout/Plugins/Launcher/index.html')
        self.spr.listenForHotkey(49, False, True, False, False, lambda a, b, c, d, e : self.toggleWindowHide())
        self.plugins = []
        self._results = [] # (key, priority, displayHTML)
        self._resultsChanged()

    def toggleWindowHide(self):
        isVisible = self._window.visible()
        if isVisible: self._window.returnOwnership()
        else:
            self._window.borrowOwnership()
            self._window.sendMessage('clear')

    def server(self, requestStr):
        tabIndex = requestStr.find('\t')
        if tabIndex == -1: tabIndex = len(requestStr)
        command = requestStr[0:tabIndex]
        commandArgs = requestStr[tabIndex+1:]
        if (command.lower() == 'query'):
            self._results = []
            self._resultsChanged()
            for plugin in self.plugins:
                plugin.query(commandArgs, lambda results: self.queryCallback(commandArgs, results))
        else:
          return

    def queryCallback(self, userInput, results):
        self._results += results
        self._resultsChanged()

    def _resultsChanged(self):
        # Sort by priority.
        self._results = sorted(self._results, key=lambda item: -item[1])
        self._window.sendMessage('suggestions\t' + json.dumps(self._results))
