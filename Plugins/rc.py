import sys
sys.path.insert(0, '/Users/thomasredding/Projects/Sprout/Plugins')

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
windowSnapper.connectHotKeyToFrame(44, True, True, False, False, 0.0, 0.0, 1.0, 1.0)



from LocationWidget import LocationWidget
locationWidget = LocationWidget.LocationWidget(spr)

import os
from TimeTracker import TimeTracker
outputPath = os.path.expanduser('~') + '/Desktop/time-tracking/'
timeTracker = TimeTracker.TimeTracker(spr, outputPath, 10)

from Launcher import Launcher
launcher = Launcher.Launcher(spr)

from Calculator import Calculator
calculator = Calculator.Calculator()
launcher.plugins.append(calculator)

from GoogleSearch import GoogleSearch
googleSearch = GoogleSearch.GoogleSearch(spr)
launcher.plugins.append(googleSearch)

spr.print('END LOADING')
