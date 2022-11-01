The Useless Pet
====

Introduction
----

This project came to be because I found a thermal printer and wanted to print out fortunes.  In the process, I learned quite a bit about mechanical and electronic design.  This repository hosts the end result of these experiments.  There is much room for improvement with a v2, but I am unlikely to resume this project in the near future.  I can say that a fortune printing robot is a hit at parties.

API
----

The `api/` folder contains the files necessary to serve fortunes from the [UNIX fortune-mod](https://github.com/shlomif/fortune-mod) project.  It uses [FastAPI](https://github.com/tiangolo/fastapi) and is extremely basic.

Models
----

The `models/` folder contains the [OpenSCAD](https://openscad.org/) file used to render models for all plastic parts.  For the most part this can be tuned by changing variables, but some interrelated dimensions may not be entirely parametric as of this writing.  The `sg90.stl` file imported by the code (not included) is a model I found on Thingiverse and is only used for rendering previews, it can be safely ignored.

SRC
----

The `src/` folder contains the micropython source files used in this project.  `vector3d.py`, `imu.py`, and `mpu9250.py` come from [micropython-IMU/micropython-mpu9x50](https://github.com/micropython-IMU/micropython-mpu9x50).  `deltat.py` and `fusion.py` are from the [micropython-IMU/micropython-fusion](https://github.com/micropython-IMU/micropython-fusion) project and help translate the sensor data to heading, pitch, and roll information.  The `thermal.py` file is renamed from `Adafruit_Thermal.py` found in their [Python-Thermal-Printer](https://github.com/adafruit/Python-Thermal-Printer) repository.  The `button.py` and `servo.py` libraries are my own and require some additional work.  Namely the button is only firing once per press (by design) but that should be a different function from debouncing.  The servo has some old PID related code that was not used in the final project and probably needs more cleanup as well.  Finally, `main.py` contains the main program.  The eye code needs considerable work here to match reality, but the basic functionality is in place.

Picture
----

![image](https://user-images.githubusercontent.com/1106212/199348549-666e5ec5-8a13-414b-a9bf-a12cd8e44550.png)
