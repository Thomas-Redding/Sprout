from math import *
import os

"""
launcherCalculator = Launcher_Calculator()
launcherCalculator.priority = 15
"""

class Launcher_Calculator:

    def __init__(self):
        self.priority = 0
        self.supportedMethods = {'acos': acos, 'asin': asin, 'atan': atan, 'atan2': atan2, 'ceil': ceil,
            'cos': cos, 'cosh': cosh, 'degrees': degrees, 'e': e, 'exp': exp, 'abs': fabs, 'floor': floor,
            'fmod': fmod, 'frexp': frexp, 'hypot': hypot, 'ldexp': ldexp, 'log': log, 'log10': log10,
            'modf': modf, 'pi': pi, 'pow': pow, 'radians': radians, 'sin': sin, 'sinh': sinh, 'sqrt': sqrt,
            'tan': tan, 'tanh': tanh }

    def query(self, userInput, callback):
        userInput = userInput.replace('^', '**')
        result = None
        try: result = str(eval(userInput, {"__builtins__":None}, self.supportedMethods))
        except: return None
        callback([('Launcher_Calculator:' + result, self.priority, '=' + result)])

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:20] == 'Launcher_Calculator:':
            # Copy to clipboard.
            os.system('echo "' + key[20:] + '" | tr -d "\n" | pbcopy')
            return True
        return False
