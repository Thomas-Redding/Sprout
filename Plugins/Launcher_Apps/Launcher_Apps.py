import json
import os
import time

class Launcher_Apps:
    def __init__(self, spr):
        self.spr = spr
        self.launchPriority = 0
        self.quitPriority = 0
        self.restartPriority = 0
        self.appPriority = {}

    def _getAppPriority(self, path):
        return self.appPriority[path] if path in self.appPriority else 0

    def query(self, userInput, callback):
        response = []
        if userInput[0:5] == 'quit ':
            runningApps = self.spr.runningApps()
            query = userInput[5:]
            for file in os.listdir('/Applications'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if query.lower() == appName[0:len(query)].lower():
                    if self.does2dArrayContain(runningApps, appName):
                        response.append(['Launcher_Apps:quit /Applications/' + file, self.quitPriority + self._getAppPriority("/Applications/" + file), self.imageHTML("/Applications/" + file) + 'quit ' + appName])
            for file in os.listdir('/Applications/Utilities'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if query.lower() == appName[0:len(query)].lower():
                    if self.does2dArrayContain(runningApps, appName):
                        response.append(['Launcher_Apps:quit /Applications/Utilities/' + file, self.quitPriority + self._getAppPriority("/Applications/Utilities" + file), self.imageHTML("/Applications/Utilities" + file) + 'quit ' + appName])
        elif userInput[0:8] == 'restart ':
            runningApps = self.spr.runningApps()
            query = userInput[8:]
            for file in os.listdir('/Applications'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if query.lower() == appName[0:len(query)].lower():
                    if self.does2dArrayContain(runningApps, appName):
                        response.append(['Launcher_Apps:restart /Applications/' + file, self.restartPriority + self._getAppPriority("/Applications/" + file), self.imageHTML("/Applications/" + file) + 'restart ' + appName])
            for file in os.listdir('/Applications/Utilities'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if query.lower() == appName[0:len(query)].lower():
                    if self.does2dArrayContain(runningApps, appName):
                        response.append(['Launcher_Apps:restart /Applications/Utilities/' + file, self.restartPriority + self._getAppPriority("/Applications/Utilities" + file), self.imageHTML("/Applications/Utilities" + file) + 'restart ' + appName])
        else:
            for file in os.listdir('/Applications'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if userInput.lower() == appName[0:len(userInput)].lower():
                    response.append(['Launcher_Apps:open /Applications/' + file, self.launchPriority + self._getAppPriority("/Applications/" + file), self.imageHTML("/Applications/" + file) + appName])
            for file in os.listdir('/Applications/Utilities'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if userInput.lower() == appName[0:len(userInput)].lower():
                    response.append(['Launcher_Apps:open /Applications/Utilities/' + file, self.launchPriority + self._getAppPriority("/Applications/Utilities" + file), self.imageHTML("/Applications/Utilities" + file) + appName])
        callback(response)

    def does2dArrayContain(self, arr2d, val):
        for x in arr2d:
            for y in x:
                if y == val: return True
        return False

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:14] == 'Launcher_Apps:':
            if key[14:19] == 'open ':
                os.system('open "' + key[19:] + '"')
                return True
            elif key[14:19] == 'quit ':
                self.spr.runAppleScript('quit app "' + key[19:] + '"')
                return True
            elif key[14:22] == 'restart ':
                self.spr.runAppleScript('quit app "' + key[22:] + '"')
                time.sleep(0.1)
                os.system('open "' + key[22:] + '"')
                return True
        return False

    def imageHTML(self, path):
        return "<img src='" + self.spr.pathToFileIcon(path) + "'>"
