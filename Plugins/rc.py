import sys
sys.path.insert(0, '/Users/thomasredding/Projects/Sprout/Plugins')

from WindowSnapper import WindowSnapper
windowSnapper = WindowSnapper.WindowSnapper(spr)
windowSnapper.padding = 20

from Calculator import Calculator
calculator = Calculator.Calculator(spr)
calculator.supportedMethods['sq'] = lambda x : x*x
