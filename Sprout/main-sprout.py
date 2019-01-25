import time

WAIT_TIME = 0.5

spr.listenForHotkey(49, True, False, False, False, lambda a, b, c, d, e : None)
time.sleep(WAIT_TIME)
wind = spr.makeWindow()
time.sleep(WAIT_TIME)
spr.print('WINDOW FRAME:' + str(wind.frame()))
wind.setFrame([100, 100, 300, 300])
spr.print('WINDOW FRAME:' + str(wind.frame()))
time.sleep(WAIT_TIME)
wind.onLoad = lambda : spr.print('I Loaded!!!')
wind.setIndexPath('~/Projects/Sprout/Sprout/index.html')
time.sleep(WAIT_TIME)
spr.print('WINDOW FRAME:' + str(wind.frame()))
wind.setFrame([100, 100, 400, 400])
spr.print('WINDOW FRAME:' + str(wind.frame()))
time.sleep(WAIT_TIME)
spr.print('WINDOW FRAME:' + str(wind.frame()))
time.sleep(WAIT_TIME)
wind.close()
time.sleep(WAIT_TIME)
spr.quit()
