import json
import os

class Launcher_Apps:
    def __init__(self, spr):
        self.spr = spr

    def query(self, userInput, callback):
        response = []
        runningApps = self.spr.runningApps()
        for file in os.listdir('/Applications'):
            if file == '.DS_Store': continue
            appName = file[0:-4]
            if userInput.lower() == appName[0:len(userInput)].lower():
                response.append(['Launcher_Apps:open /Applications/' + file, 0, 'launch ' + appName])
        for file in os.listdir('/Applications/Utilities'):
            if file == '.DS_Store': continue
            appName = file[0:-4]
            if userInput.lower() == appName[0:len(userInput)].lower():
                response.append(['Launcher_Apps:open /Applications/Utilities/' + file, 0, appName])
        if userInput[0:5] == 'quit ':
            query = userInput[5:]
            for file in os.listdir('/Applications'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if query.lower() == appName[0:len(query)].lower():
                    if self.does2dArrayContain(runningApps, appName):
                        response.append(['Launcher_Apps:quit /Applications/' + file, 0, 'quit ' + appName])
            for file in os.listdir('/Applications'):
                if file == '.DS_Store': continue
                appName = file[0:-4]
                if query.lower() == appName[0:len(query)].lower():
                    if self.does2dArrayContain(runningApps, appName):
                        response.append(['Launcher_Apps:quit /Applications/Utilities/' + file, 0, 'quit ' + appName])
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
        return False
