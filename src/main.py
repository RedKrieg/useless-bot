import gc
import json
import network
import rp2
import time
import _thread
import urequests
from button import Button
from fusion import Fusion
from machine import I2C, Pin, PWM
from mpu9250 import MPU9250
from random import choice
from servo import Servo
from thermal import ThermalPrinter

# connect to the internet
rp2.country("US") # make sure we use the right wifi channels
with open("wlan.json", "r") as f:
    wlan_config = json.load(f)
wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect(wlan_config["ssid"], wlan_config["pass"])

# Inertial Measurement, Gyro, and Mag sensors
# https://github.com/micropython-IMU/micropython-mpu9x50/blob/master/README_MPU9150.md
imu_i2c = I2C(0, sda=Pin(16), scl=Pin(17))
imu = MPU9250(imu_i2c)
imu.accel_range = 1 # max 4g
imu.gyro_range = 2 # 1000 degrees/s is ~166rpm
imu.filter_range = 1 # 2ms delay
imu.accel.xyz, imu.gyro.xyz, imu.mag.xyz # trigger a read of each device
time.sleep_ms(20) # give magnetometer time to wake up
# https://github.com/micropython-IMU/micropython-fusion
fuse = Fusion()
fuse.update(imu.accel.xyz, imu.gyro.xyz, imu.mag.xyz)

# servo setup
pitch_servo = Servo(18)
roll_servo = Servo(19)
min_ms = 20 # two 10ms cycles of the servo pwm clock, one cycle of the magnetometer's resolution

# printer setup
print_lock = _thread.allocate_lock()
print_start = False
print_command = False
printer = ThermalPrinter(bus=1, baudrate=9600, pins=(Pin(4), Pin(5)), heatdots=16, heattime=180, heatinterval=50)
print_button = Button(10)

def wrap(text, cols=32):
    """Non-regex text wrapping"""
    punctuation = ".:;!?"
    out_lines = []
    lines = text.splitlines()
    cur_line = []
    line_len = 0
    for line in lines:
        splitwords = []
        words = line.split()
        for word in words:
            chunks = word.split("-")
            for i in range(len(chunks)-1):
                chunks[i] += "-"
            for chunk in chunks:
                splitwords.append(chunk)
        while len(splitwords):
            word = splitwords.pop(0)
            if len(word) + line_len <= cols:
                line_len += len(word)
                if not word.endswith('-') and line_len < cols:
                    word = word + " "
                    line_len += 1
                cur_line.append(word)
            else:
                out_lines.append("".join(cur_line))
                if not word.endswith('-'):
                    line_len = len(word) + 1
                    cur_line = [word + " "]
                else:
                    line_len = len(word)
                    cur_line = [word]
        if cur_line[-1][-1] in punctuation:
            out_lines.append("".join(cur_line))
            line_len = 0
            cur_line = []
    if len(cur_line):
        out_lines.append("".join(cur_line))
    return "\n".join(out_lines)

def get_fortune(wlan):
    # http://yerkee.com/api/fortune
    # {"fortune":"Absence makes the heart grow frantic."}
    # http://digital-fortune-cookies-api.herokuapp.com/fortune
    # {"success":true,"cookie":{"fortune":"If you have something good in your life, don't let it go!","luckyNumbers":[5,15,29,45,53,90]}}
    if wlan.status() != 3:
        msg = f"No fortune today, internet's down.\n\nStatus code: {wlan.status()}"
        if wlan.status() == -2: # not able to find AP previously
            wlan.disconnect()
            wlan.connect(wlan_config["ssid"], wlan_config["pass"])
        return wrap(msg)
    categories = ("cookie", "miscellaneous", "people", "science", "wisdom")
    #fortune_url = f"https://yerkee.com/api/fortune/{choice(categories)}"
    #fortune_url = "http://digital-fortune-cookies-api.herokuapp.com/fortune"
    fortune_url = "http://fortune.redkrieg.com/"
    try:
        r = urequests.get(fortune_url, headers={"User-Agent": "UselessBot/0.0.1 redkrieg@gmail.com"})
        data = r.json()
        #fortune = wrap(f"{data['cookie']['fortune']}\n{str(data['cookie']['luckyNumbers']):^32s}", 32)
        fortune = wrap(data["fortune"], 32)
        r.close()
    except (OSError, ValueError):
        if wlan.status() < 0 or wlan.status() >= 3:
            wlan.disconnect()
            wlan.connect(wlan_config["ssid"], wlan_config["pass"])
        fortune = "No fortune today, internet's down."
    return fortune

def modulo_angle(theta, mod_range=180):
    return (theta + mod_range / 2) % mod_range - mod_range / 2

def cycling_angle(theta, cycle_range=180):
    modded = modulo_angle(theta, cycle_range)
    modded *= (-1) ** ((abs(theta) // (cycle_range / 2)) % 2)
    return modded

def main_thread():
    global print_lock
    global print_start
    last_time = time.ticks_ms()
    while True:
        start_ticks = time.ticks_ms()
        temp = imu.temperature
        accel = imu.accel.xyz
        gyro = imu.gyro.xyz
        mag = imu.mag.xyz
        fuse.update(accel, gyro, mag)
        pitch_servo.update(cycling_angle(fuse.pitch))
        roll_servo.update(cycling_angle(fuse.roll))
        if print_button.debounced():
            with print_lock:
                print_start = True
        gc.collect()
        end_ticks = time.ticks_ms()
        dt = time.ticks_diff(end_ticks, start_ticks)
        print(f"Temp: {temp} C, Heading: {fuse.heading}, Pitch: {pitch_servo.theta}, Roll: {roll_servo.theta}, Duration: {dt} ms, Print: {print_start}")
        time.sleep_ms(min_ms - dt)

# put the main loop on the second thread because using wlan from the second thread seems to always report status "1"
_thread.start_new_thread(main_thread, ())
while True:
    with print_lock:
        print_command = print_start
        if print_start:
            print_start = False
    if print_command:
        printer.println(get_fortune(wlan))
        printer.feed(4)
        print_command = False
    time.sleep_ms(20)
