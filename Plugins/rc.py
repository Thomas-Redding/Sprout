import sys
sys.path.insert(0, '/Users/thomasredding/Projects/Sprout/Plugins')

spr.listenForHotkey(44, True, True, False, False, lambda a, b, c, d, e : spr.quitSprout())

spr.print('BEGIN LOADING')

from WindowSnapper import WindowSnapper
windowSnapper = WindowSnapper.WindowSnapper(spr)
windowSnapper.padding = 20
# CMD + OPT + LeftArrow
windowSnapper.connectHotKeyToFrame(123, True, True, False, False, 0.0, 0.0, 0.5, 1.0)
# CMD + OPT + RightArrow
windowSnapper.connectHotKeyToFrame(124, True, True, False, False, 0.5, 0.0, 0.5, 1.0)
# CMD + OPT + DownArrow
windowSnapper.connectHotKeyToFrame(125, True, True, False, False, 0.5, 0.5, 0.5, 0.5)
# CMD + OPT + UpArrow
windowSnapper.connectHotKeyToFrame(126, True, True, False, False, 0.5, 0.0, 0.5, 0.5)
# CMD + OPT + /
# windowSnapper.connectHotKeyToFrame(44, True, True, False, False, 0.0, 0.0, 1.0, 1.0)



from LocationWidget import LocationWidget
locationWidget = LocationWidget.LocationWidget(spr)

import os
from TimeTracker import TimeTracker
outputPath = os.path.expanduser('~') + '/Desktop/time-tracking/'
timeTracker = TimeTracker.TimeTracker(spr, outputPath, 10)


from Launcher import Launcher
launcher = Launcher.Launcher(spr)

from Launcher_Calculator import Launcher_Calculator
calculatorLauncher = Launcher_Calculator.Launcher_Calculator()
launcher.plugins.append(calculatorLauncher)

from Launcher_GoogleSearch import Launcher_GoogleSearch
googleSearchLauncher = Launcher_GoogleSearch.Launcher_GoogleSearch(spr)
launcher.plugins.append(googleSearchLauncher)

from Launcher_File import Launcher_File
fileLauncher = Launcher_File.Launcher_File(spr)
launcher.plugins.append(fileLauncher)

from Launcher_System import Launcher_System
launcherSystem = Launcher_System.Launcher_System(spr)
launcher.plugins.append(launcherSystem)

spr.print('END LOADING')
