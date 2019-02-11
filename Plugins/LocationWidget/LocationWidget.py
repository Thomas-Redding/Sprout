# pip install geocoder
import geocoder

class LocationWidget:

    def __init__(self, spr):
        self.spr = spr
        self._window = self.spr.makeWindow()
        self._window.setIsWidget(True)
        self._window.setVisible(True)
        self._window.setSupportsUserActions(False)
        screenSize = self.spr.screenSize()
        self._window.setFrame([100, screenSize[1] - 200, 200, 120])
        self._window.setTitle(None)
        self._window.setIndexPath('~/Projects/Sprout/Plugins/LocationWidget/index.html')
        self.spr.repeat(600, lambda: self.update())
        self.update()

    def update(self):
        try:
            g = geocoder.ip('me')
            message = str(g.latlng[0]) + '\t' + str(g.latlng[1])
            message += '\t' + g.city
            self._window.sendMessage(message)
        except:
            None
