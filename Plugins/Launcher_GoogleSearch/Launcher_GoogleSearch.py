import json
import requests # pip install requests;
import webbrowser


class Launcher_GoogleSearch:

    def __init__(self, spr):
        self.spr = spr
        None

    def query(self, userInput, callback):
        if userInput[0:2] != 'g ': return None
        responses = self.googleSuggest(userInput[2:])
        rtn = []
        for i in range(len(responses)):
            response = responses[i]
            rtn.append(['Launcher_GoogleSearch:' + response, 5-i, 'google ' + response])
        callback(rtn)

    def action(self, key):
        if key[0:22] == 'Launcher_GoogleSearch:':
            url = 'https://www.google.com/search?q=' + key[22:].replace(' ', '+')
            webbrowser.open(url)
            return True
        return False

    def googleSuggest(self, s):
        if s == '': return []
        try:
            GOOGLE_SUGGESITON_URL = 'http://suggestqueries.google.com/complete/search?client=firefox&q='
            HEADERS = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36'}
            response = str(requests.get(GOOGLE_SUGGESITON_URL+s, headers=HEADERS).content)
            response = response[2:-1]
            response = self.unescape(response)
            with open('/Users/thomasredding/fish.txt', 'w+') as f:
                f.write(response)
            return json.loads(response)[1]
        except:
            return []

    def unescape(self, s):
        state = 0
        rtn = ''
        for c in s:
            if state == 0:
                if c == '\\': state = 1
                else: rtn += c
            else:
                if c == '\\': rtn += '\\'
                elif c == '"': rtn += '"'
                elif c == "'": rtn += "'"
                elif c == 'n': rtn += 'n'
                elif c == 't': rtn += 't'
                else:
                    print('ERROR in unescapeNewlines', s)
                    sys.exit(1)
                state = 0
        return rtn
