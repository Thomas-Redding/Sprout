from math import *

class Calculator:

    def __init__(self):
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
        callback([(result, 10, result)])

    def action(self, key):
        # TODO: Copy to clipboard.
        None
