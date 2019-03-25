import json
import os

class Launcher_Apps:
    def __init__(self, spr):
        self.spr = spr

    def query(self, userInput, callback):
        response = []
        for file in os.listdir('/Applications'):
            if file == '.DS_Store': continue
            appName = file[0:-4]
            if userInput.lower() == appName[0:len(userInput)].lower():
                response.append(['Launcher_Apps:/Applications/' + file, 0, appName])
        for file in os.listdir('/Applications/Utilities'):
            if file == '.DS_Store': continue
            appName = file[0:-4]
            if userInput.lower() == appName[0:len(userInput)].lower():
                response.append(['Launcher_Apps:/Applications/Utilities/' + file, 0, appName])
        callback(response)

    def action(self, key):
        if key[0:14] == 'Launcher_Apps:':
            self.spr.print('open "' + key[14:] + '"')
            os.system('open "' + key[14:] + '"')
            return True
        return False
