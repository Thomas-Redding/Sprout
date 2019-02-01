import sys
sys.path.insert(0, '/Users/thomasredding/Projects/Sprout/Plugins')

spr.print('BEGIN LOADING')

from WindowSnapper import WindowSnapper
windowSnapper = WindowSnapper.WindowSnapper(spr)
windowSnapper.padding = 20

from Launcher import Launcher
launcher = Launcher.Launcher(spr)

from Calculator import Calculator
calculator = Calculator.Calculator()
launcher.plugins.append(calculator)

from GoogleSearch import GoogleSearch
googleSearch = GoogleSearch.GoogleSearch(spr)
launcher.plugins.append(googleSearch)

spr.print('END LOADING')