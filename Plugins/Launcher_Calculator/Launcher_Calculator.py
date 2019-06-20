from math import *
import os
import re

"""
launcherCalculator = Launcher_Calculator()
launcherCalculator.priority = 15
"""

class Launcher_Calculator:

    def __init__(self, spr):
        self.spr = spr
        self.variables = {}
        self.priority = 0
        self.supportedMethods = {'acos': acos, 'asin': asin, 'atan': atan, 'atan2': atan2, 'ceil': ceil,
            'cos': cos, 'cosh': cosh, 'degrees': degrees, 'e': e, 'exp': exp, 'abs': fabs, 'floor': floor,
            'fmod': fmod, 'frexp': frexp, 'hypot': hypot, 'ldexp': ldexp, 'log': log, 'log10': log10,
            'modf': modf, 'pi': pi, 'pow': pow, 'radians': radians, 'sin': sin, 'sinh': sinh, 'sqrt': sqrt,
            'tan': tan, 'tanh': tanh }

    def query(self, userInput, callback):
        userInput = userInput.replace("^", "**")
        result = None
        variables = {"__builtins__":None}
        for variableName in self.variables:
            variables[variableName] = self.variables[variableName]

        eqIndex = userInput.find("=")
        expression = userInput if eqIndex == -1 else userInput[eqIndex+1:]
        variableName = None if eqIndex == -1 else userInput[:eqIndex]
        if variableName and not self._isValidVariableName(variableName):
            return None
        try:
            result = eval(expression, variables, self.supportedMethods)
        except:
            return None
        if variableName:
            self.variables[variableName] = result
        callback([('Launcher_Calculator:' + str(result), self.priority, '=' + str(result))])

    def action(self, key, cmd, opt, ctrl, shift):
        if key[0:20] == 'Launcher_Calculator:':
            # Copy to clipboard.
            os.system('echo "' + key[20:] + '" | tr -d "\n" | pbcopy')
            return True
        return False

    def _isValidVariableName(self, variableName):
        return re.match(r"^[a-zA-Z_][a-zA-Z_0-9]*$", variableName) != None
