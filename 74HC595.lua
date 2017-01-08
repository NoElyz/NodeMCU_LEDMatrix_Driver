-- 74HC595.lua
-- Written by Zyleon January 2017
-- NodeMCU connected to dual 74HC595 matrix via SPI

-- Connect Nodemcu D7 (GPIO13) to 74HC595 Data or DATA_IN(pin 14)
-- Connect Nodemcu D5 (GPIO14) to 74HC595 Clock or SCL1(pin 11)
-- Connect Nodemcu D8 (GPIO15) to 74HC595 Latch or SCL2(pin 12)

-- Connect Nodemcu D1 (GPIO5) to 74HC595 OE for PWM control over D1
-- In most matrix module, OE and GND comes to the same pin GND
local pwm_pin = 1
pwm.setup(1, 1000, 0)

--Set cpu frequendcy to 160MHz for 2x performance
node.setcpufreq(160)

local latch = 8

spi.setup(1,spi.MASTER,spi.CPOL_HIGH,spi.CPHA_LOW,spi.DATABITS_8,0)
gpio.mode(latch,gpio.OUTPUT)

-- The matrix I've got use VIL thus needs two's complement
-- as row selection
-- Select rows with input r between 0 to 255, showing different patterns
-- Select individual column with input c in [1,2,4,8,16,32,64,128] 

local function litLED(r, c)
    local gpio_write = gpio.write
    local spi_send = spi.send
    gpio_write(8, 0)     -- Set latch to VIL to input data
    spi_send(1, 255-r)              -- Send data to row selection 595
    spi_send(1, c)                  -- Send to column selection 595
    gpio_write(8, 1)    -- Set latch to VIH to output image
end

local function showFrame(frame)
    local bits = {1, 2, 4, 8, 16, 32, 64, 128}
    for i=1,8 do
        litLED(frame[i], bits[i])
    end
end


local function display(frames)
    local frames = frames
    local pwmlevel = {512, 256, 128, 0}     -- Bit Angle Modulation
    local pwm_setduty = pwm.setduty
    for i=1,4 do
        pwm_setduty(1, pwmlevel[i])
        showFrame(frames[i])
    end
end

function animation(frame_buffer)
    local pwm_setduty = pwm.setduty
    local fb = frame_buffer
    local tmr_delay = tmr.delay
    for i = 1,table.maxn(fb),4 do
        pwm_setduty(1, 512)
        showFrame(fb[i])
        litLED(1,0)
        pwm_setduty(1, 256)
        showFrame(fb[i+1])
        litLED(1,0)
        pwm_setduty(1, 128)
        showFrame(fb[i+2])
        litLED(1,0)
        pwm_setduty(1, 0)
        showFrame(fb[i+3])
        tmr_delay(10)
        litLED(1, 0)
    end
end


happy = {0x3C, 0x42, 0xA5, 0x81, 0xA5, 0x99, 0x42, 0x3C}
frown = {0x3C, 0x42, 0xA5, 0x81, 0xBD, 0x81, 0x42, 0x3C}
sad = {0x3C, 0x42, 0xA5, 0x81, 0x99, 0xA5, 0x42, 0x3C}
faces = {happy, frown, sad}

function moody()
    local tmr_delay = tmr.delay
    for i=1,10 do 
        for j=1,50 do
            display({faces[i%3+1], faces[i%3+1],
             faces[i%3+1], faces[i%3+1]})
            tmr_delay(50)
        end
    end
end
