import serial
import time
ser = serial.Serial("/dev/ttyS0", 115200)
ser.write("UART the Font")
time.sleep(1)
read = ser.read()
print read
ser.close()
