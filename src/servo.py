from machine import Pin, PWM
#from pid import PID
from time import ticks_us

class Servo:
    def __init__(
            self,
            pin_id,
            duty_min=450000,
            duty_max=2400000,
            freq=100,
            #pid_p=0.8,
            #pid_i=0.000005,
            #pid_d=0.6,
            update_threshold=0.5,
            smoothing_factor=0.25
        ):
        self.duty_min = duty_min
        self.duty_max = duty_max
        self.duty_range = duty_max - duty_min
        self.pwm = PWM(Pin(pin_id))
        self.pwm.freq(freq)
        self.set_duty(int(self.duty_range/2+self.duty_min))
        self.sample_ms = int(1000.0/freq)
        """
        self.pid = PID(
            Kp=pid_p,
            Ki=pid_i,
            Kd=pid_d,
            setpoint=self.duty,
            output_limits=(-self.duty_min, self.duty_min),
            sample_time=self.sample_ms
        )
        self.pid.time_fn = ticks_us
        """
        self.update_threshold = update_threshold
        self.smoothing_factor = smoothing_factor
        self.theta = 0

    def clamp_angle(self, theta):
        if theta > 90.0:
            theta = 90.0
        elif theta < -90.0:
            theta = -90.0
        return theta

    def angle_to_servo(self, theta):
        theta = self.clamp_angle(theta)
        return int((theta+90)*self.duty_range/180)+self.duty_min
        
    def set_duty(self, duty):
        self.duty = int(duty)
        self.pwm.duty_ns(self.duty)

    def update(self, theta=None):
        if (
            theta is not None and
            abs(self.theta-theta) >= self.update_threshold
        ):
            theta = self.clamp_angle(theta)
            theta = theta * self.smoothing_factor + self.theta * (1 - self.smoothing_factor)
            #self.pid.setpoint = self.angle_to_servo(theta)
        else:
            theta = self.theta
        self.set_duty(self.angle_to_servo(theta))
        self.theta = theta
