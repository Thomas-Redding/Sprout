import json
import os
import time

class Launcher_Simple:
    def __init__(self, spr):
        self.spr = spr
        self._simpleActions = {}

    def addSimpleAction(self, keyword, priority, callback):
        self._simpleActions[keyword] = (priority, callback)

    def query(self, userInput, callback):
        response = []
        for keyword in self._simpleActions:
            if userInput.lower() == keyword[0:len(userInput)].lower():
                priority, _ = self._simpleActions[keyword]
                response.append(["Launcher_Simple:" + keyword, priority, keyword])
        callback(response)

    def action(self, key, cmd, opt, ctrl, shift):
        self.spr.log("bar")
        if key[0:16] != 'Launcher_Simple:': return False
        keyword = key[16:]
        self._simpleActions[keyword][1]()
        return True
