import serial
import colorsys
import math
ser = serial.Serial('/dev/ttyS0', baudrate=115200)
import math
import time
ser.isOpen()
numLEDs = 32
from phue import Bridge

def hueTest():
    #b = Bridge('192.168.1.140')
    #b.connect()

    ser.read(ser.inWaiting())
    time.sleep(0.7)
    while(ser.inWaiting() < 6):
        pass
    time.sleep(.05)
    ser.read(ser.inWaiting())


    while(True):
        read = ""
        while(ser.inWaiting() < 6):
            pass
        s = ser.read(6)
        for i in s:
            read +=  str(int(i.encode('hex'), 16)) + ", "
        print(read)
            




def boot():
    numBlocks =  32
    numVertBlocks = 6
    numHorzBlocks = 10

    colorSweepTime = 2
    rainbowCycleTime = 1
    
    done = False
    verticalMask = [False] * numVertBlocks 
    horzentalMask = [False] * numHorzBlocks 

    verticalMaskIndex = 0
    horzentalMaskIndex = 0

    huePerHorzinal = 1 / (numHorzBlocks * 1.0)
    huePerVertical = 1 / (numVertBlocks * 1.0)

    timePerVertBlock = colorSweepTime / (numVertBlocks * 1.0)
    timePerHorzBlock = colorSweepTime / (numHorzBlocks * 1.0)
    print(timePerVertBlock, timePerHorzBlock)

    lastVertMaskUpdate = time.time()
    lastHorzMaskUpdate = time.time()

    startTime = time.time()
    while not done:
        currentTime = time.time()
        if currentTime - startTime > colorSweepTime:
            break

        if currentTime - lastHorzMaskUpdate >= timePerHorzBlock:
            lastHorzMaskUpdate = currentTime
            if verticalMaskIndex < len(verticalMask):
                verticalMask[verticalMaskIndex] = True
                verticalMask[-1 * (verticalMaskIndex+1)] = True 
                verticalMaskIndex += 1

        if currentTime - lastVertMaskUpdate >= timePerVertBlock:
            lastHorzMaskUpdate = currentTime
            if(horzentalMaskIndex < len(horzentalMask)):
                horzentalMask[horzentalMaskIndex] = True
                horzentalMask[-1 * (horzentalMaskIndex+1)] = True
                horzentalMaskIndex += 1

        startHue = (currentTime - startTime) - int(currentTime - startTime) 
        currentBuffer = [0x00] * (numBlocks/2) * 3
        grb = [0,0,0]
        
        for i in range(0, numHorzBlocks/2):
            if horzentalMask[i]:
                currentColor = colorsys.hsv_to_rgb(startHue + i * huePerHorzinal, 1,1)
                grb[0] = int(currentColor[1]*255)
                grb[1] = int(currentColor[0]*255)
                grb[2] = int(currentColor[2]*255)
                currentBuffer[i*3] = grb[0]
                currentBuffer[i*3 + 1] = grb[1]
                currentBuffer[i*3 + 2] = grb[2]
                currentBuffer[numHorzBlocks-i*3 -1 ] = grb[0]
                currentBuffer[numHorzBlocks-i*3 - 2] = grb[1]
                currentBuffer[numHorzBlocks-i*3 - 3] = grb[2]

                
        for i in range(0, numVertBlocks/2):   
            if verticalMask[i]:
                currentColor = colorsys.hsv_to_rgb(startHue + i * huePerVertical, 1,1)
                grb[0] = int(currentColor[1]*255)
                grb[1] = int(currentColor[0]*255)
                grb[2] = int(currentColor[2]*255)
                currentBuffer[numHorzBlocks+ i*3] = grb[0]
                currentBuffer[numHorzBlocks+i*3 + 1] = grb[1]
                currentBuffer[numHorzBlocks+i*3 + 2] = grb[2]
                currentBuffer[-1 * i*3 - 1] = grb[0]
                currentBuffer[-1 * i*3 - 2] = grb[1]
                currentBuffer[-1 * i*3 - 3] = grb[2]
        currentBuffer = currentBuffer + currentBuffer[::-1]

        ser.write(bytearray([0x02]))
        ser.write(bytearray(currentBuffer))
        time.sleep(0.01)






def writeBlockCount():
    currentBuffer = [0xA] * (numLEDs)
    ser.write(bytearray([0x01]))
    ser.write(bytearray(currentBuffer))

def shift():
    currentBuffer = [0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0xFF, 0x00] * int(numLEDs/3) 
    while True:
        ser.write(bytearray([0x02]))
        ser.write(bytearray(currentBuffer))
        print(str(len(currentBuffer))+ " "  + str(currentBuffer) + '\n\n'   )
        currentBuffer =  currentBuffer[1:] + currentBuffer[0:1]
        break
        time.sleep(0.5)



def rainbow():
    currentBuffer=[0x00] * numLEDs *3
    while True:
        for i in range(0,100,5):
            currentColor = colorsys.hsv_to_rgb(i/100.0, 1,1)
            grb = [0,0,0]
            grb[0] = int(currentColor[1]*255)
            grb[1] = int(currentColor[0]*255)
            grb[2] = int(currentColor[2]*255)
            currentBuffer = grb + currentBuffer[0:-3]
            print(grb)
            ser.write(bytearray([0x02]))
            ser.write(bytearray(currentBuffer)) 
            time.sleep(0.016)

def grbCycle():
    while True: 
        for i in range(3):
            ser.write(bytearray([0x02]))
            if i%3 == 0:
                ser.write(bytearray([0xFF,0x80,0x80] * numLEDs))
            elif i%3 == 1:
                ser.write(bytearray([0x80,0xFF,0x80] * numLEDs))
            else:
                ser.write(bytearray([0x80,0x80,0xFF] * numLEDs))
            time.sleep(1)

def colorPulse():
    currentValue = 1
    currentIndex = 0
    direction = 'up'
    while True:
        if direction == 'up':
            currentValue += 1
            if currentValue == 255:
                direction = 'down'
        else:
            currentValue -= 1
            if currentValue == 0:
                direction == 'up'
                currentIndex = (currentIndex + 1) %3
        print(direction, currentIndex, currentValue)
        grb = [0x0F]*3
        grb[currentIndex] = int(bin(currentValue)[:1:-1], 2)    
        ser.write(bytearray([0x02]))
        ser.write(bytearray(grb * numLEDs))
        time.sleep(0.01)


def oneLED():
    ser.write(bytearray([0x02]))
    ser.write(bytearray([0x80, 0, 0]))
    ser.write(bytearray([0x00, 0x00, 0x00] * (numLEDs -1)))

def setMode(mode):
    ser.write(bytearray([0x00]))
    ser.write(bytearray([mode]))



def generate_block_starts(vertBlocks, horizBlocks):

    block_height = 128
    block_width = 128

    deltaX = (1280.0 - 128) / (horizBlocks)
    deltaY = (720.0 - 128) / (vertBlocks)

    print(deltaX, deltaY)

    lastX = 0
    lastY = 0
    y_vals = [0]
    x_vals = [0]

    for i in range(1,  2 * vertBlocks + 2 * horizBlocks -1 ):
        #Top Row
        if i < horizBlocks - 1: #Top row becideds last one
            x_vals.append(deltaX + x_vals[-1])
            y_vals.append(0)
        elif i <= horizBlocks: # put last one along the edge, twice
            x_vals.append(1280 - 128)
            y_vals.append(y_vals[-1])
        #Left
        elif i < (vertBlocks + horizBlocks - 1): #we are
            x_vals.append(x_vals[-1])
            y_vals.append(y_vals[-1] + deltaY)
        elif i <= vertBlocks + horizBlocks :
            x_vals.append(x_vals[-1])
            y_vals.append(720 - 128)
        #Bottom
        elif i < vertBlocks + 2 * horizBlocks - 1: 
            x_vals.append(x_vals[-1] - deltaX)
            y_vals.append(y_vals[-1])
        #BL Corner
        elif i <= vertBlocks + 2 * horizBlocks :
            x_vals.append(0)
            y_vals.append(y_vals[-1])
        #Right
        else:
            y_vals.append(y_vals[-1] - deltaY)
            x_vals.append(0)
    x_vals.append(0)
    y_vals.append(0)

    roundedX =[ int(round(x)) for x in x_vals]
    roundedY =[ int(round(y)) for y in y_vals]

    for i in range( len(roundedY)):
        print(i, roundedX[i],roundedY[i])

    print(roundedX)
    print(roundedY)


def writeColor(color, color2 = None):
	while True:
		ser.write(bytearray([0x02]))
		ser.write(bytearray(color * numLEDs))
		time.sleep(0.01)
		
generate_block_starts(6,10)
writeBlockCount()
setMode(1)
#writeColor([0x00, 0x00, 0x00])
#rainbow()
#hueTest()

"""
for i in range(360):
    ser.write(bytearray([0x02]))
    currentColor = colorsys.hsv_to_rgb(i/360.0, 1,1)
    grb = [0,0,0]
    print(currentColor  )
    grb[0] = int(currentColor[1]*255)
    grb[1] = int(currentColor[0]*255)
    grb[2] = int(currentColor[2]*255)
    print(grb)
    for j in range(numLEDs):
        ser.write(bytearray(grb))
        ser.read()
        pass
    time.sleep(.1)
ser.close()



"""