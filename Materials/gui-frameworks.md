# Choice of GUI Framework

## Top Contenders

### Kivy

**Non-Code Considerations**

Kivy has [11 core developers](https://kivy.org/#aboutus) and has had [active development](https://github.com/kivy/kivy/graphs/commit-activity) [since 2011](https://github.com/kivy/kivy/releases).

**Code Cosiderations**

- Kivy only supports one window - though there are some tedious hacks to support multiple.

### Tkinter

**Non-Code Considerations**

Tkinter is part of Python itself - it ain't going anywhere.

- Tkinter creates a new application named "Python". We can rename the window and the Menu Bar item, but I can't figure out how to alter the the popup in Menu Bar > Sprout > About. Investigation is also needed into removing the app icon in the Dock on macOS.

### wxPython

**Non-Code Considerations**

wxPython is published under a unique license that is effectively the Library General Public Licence (a leftright license) but that allows the distribution of binaries (but not code) for commercial use. This might be acceptable. It does support macOS, Windows, and Linux.

wxPython has [multiple](https://github.com/wxWidgets/wxWidgets/graphs/contributors) [contributes](https://github.com/wxWidgets/Phoenix/graphs/contributors) and has had active development since before 2000.

## Other Contenders (Crossplatform + Fine License)

### PyOpenGL

PyOpenGL has [only one active developer](https://github.com/mcfletch/pyopengl/graphs/contributors).

### PyGObject

PyGObject has only one [one active developer](https://gitlab.gnome.org/GNOME/pygobject/activity).

### libavg

Libavg has [no active development](https://github.com/libavg/libavg/graphs/commit-activity).

## Rejections

### PyQt and wxPython

We can't use PyQt because it is published under the GNU General Public License, which requires derivative software to use the same license.

### PyGTK

PyGTK has been succeeded by PyGObject.

### PySide

PySide doesn't appear to *have* a license.

## To Consider

### PyGUI

### 