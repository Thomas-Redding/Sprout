spr.print('BEGIN LOADING')

import os
import sys
sys.path.insert(0, '/Users/thomasredding/proj/Sprout/Plugins')

from WindowSnapper import WindowSnapper

windowSnapper = WindowSnapper.WindowSnapper(spr)
windowSnapper.padding = 1
windowSnapper.extraCornerPading = 40
# CMD + OPT + LeftArrow
windowSnapper.connectHotKeyToFrame(123, True, True, False, False, 0.0, 0.0, 0.5, 1.0)
# CMD + OPT + RightArrow
windowSnapper.connectHotKeyToFrame(124, True, True, False, False, 0.5, 0.0, 0.5, 1.0)
# CMD + OPT + DownArrow
windowSnapper.connectHotKeyToFrame(125, True, True, False, False, 0.5, 0.5, 0.5, 0.5)
# CMD + OPT + UpArrow
windowSnapper.connectHotKeyToFrame(126, True, True, False, False, 0.5, 0.0, 0.5, 0.5)
# CMD + OPT + /
windowSnapper.connectHotKeyToFrame(44, True, True, False, False, 0.0, 0.0, 1.0, 1.0)



from LocationWidget import LocationWidget
locationWidget = LocationWidget.LocationWidget(spr)



import os
from TimeTracker import TimeTracker
outputPath = os.path.expanduser('~') + '/Desktop/time-tracking/'
timeTracker = TimeTracker.TimeTracker(spr, outputPath, 10)



from Launcher import Launcher
launcher = Launcher.Launcher(spr, 49, True, False, False, False)

from Launcher_Apps import Launcher_Apps
appsLauncher = Launcher_Apps.Launcher_Apps(spr)
appsLauncher.launchPriority = 0
appsLauncher.quitPriority = 0
appsLauncher.restartPriority = 0
appsLauncher.aliases = {
    "Chrome": "Applications/Google Chrome.app",
    "Preferences": "Applications/System Preferences.app",
    "LoL": "Applications/League of Legends.app",
    "Legends": "Applications/League of Legends.app",
    "Control": "Applications/Mission Control.app",
}
launcher.plugins.append(appsLauncher)

from Launcher_File import Launcher_File
fileLauncher = Launcher_File.Launcher_File(spr)
fileLauncher.fileKeyword = "o"
fileLauncher.folderKeyword = "fo"
fileLauncher.scopes = ['~/Desktop', '~/Downloads', '~/proj']
def openFile(path, command, option, control, shift):
    if command:
        os.system('open ' + os.path.split(path)[0])
    else:
        os.system('open ' + path)
fileLauncher.handleSelection = openFile
launcher.plugins.append(fileLauncher)

from Launcher_Calculator import Launcher_Calculator
pythonEvaluatorLauncher = Launcher_Calculator.Launcher_Calculator(spr)
pythonEvaluatorLauncher.priority = 100
launcher.plugins.append(pythonEvaluatorLauncher)

from Launcher_GoogleSearch import Launcher_GoogleSearch
googleSearchLauncher = Launcher_GoogleSearch.Launcher_GoogleSearch(spr)
googleSearchLauncher.maxPriority = 0
googleSearchLauncher.minPriority = 0
launcher.plugins.append(googleSearchLauncher)

from Launcher_System import Launcher_System
launcherSystem = Launcher_System.Launcher_System(spr)
launcherSystem.sleepPriority = 0
launcherSystem.shutdownPriority = 0
launcherSystem.restartPriority = 0
launcher.plugins.append(launcherSystem)

from Launcher_Dictionary import Launcher_Dictionary
launcherDictionary = Launcher_Dictionary.Launcher_Dictionary(spr)
launcherDictionary.priority = 0
launcher.plugins.append(launcherDictionary)

from Launcher_Contacts import Launcher_Contacts
launcherContacts = Launcher_Contacts.Launcher_Contacts(spr)
launcherContacts.priority = 0
launcher.plugins.append(launcherContacts)

spr.print('END LOADING')
