---
title: "A Simple Pibell"
date: 2020-05-05T21:59:53Z
---

With all this free time I finally got around to installing a doorbell at
home. I had no interest in Ring or the like: what I really wanted was a
simple push doorbell that fit the (Victorian) house but would also
somehow notify me if I was downstairs...

There are several documented projects on splicing in a Raspberry Pi into
existing powered doorbell systems, but that wasn't what I wanted either.

Instead, the doorbell is a simple contact switch feeding into the Pi's
GPIO pins. It's effectively extremely simple but I didn't find a step by
step, so this is what I could have done with reading.

I bought the Pi, a case, a power supply, an SD card, and a USB speaker:

[![Raspberry Pi 3 A+](/blog/posts/images/pi-3-a+.jpg)](https://shop.pimoroni.com/products/raspberry-pi-3-a-plus)
[![Pibow Coupé case](/blog/posts/images/pibow-coupe-case.jpg)](https://shop.pimoroni.com/products/pibow-3-a-plus-coupe?variant=17988388061267)
[![Pi power supply](/blog/posts//images/pi-power-supply.jpg)](https://uk.rs-online.com/web/p/ac-dc-adapters/1034301/)
[![NOOBS pre-installed SD Card](/blog/posts/images/noobs-sd-card.jpg)](https://shop.pimoroni.com/products/noobs-32gb-microsd-card-3-1)
[![USB speaker](/blog/posts/images/usb-speaker.jpg)](https://thepihut.com/products/mini-external-usb-stereo-speaker)

And the doorbell itself plus wiring:

[![Brass push doorbell](/blog/posts/images/brass-doorbell.jpg)](https://www.broughtons.com/store/product/86213/edwardian-rectangular-door-bell-push-antique-satin-brass/)
[![Bell wire](/blog/posts/images/bell-wire.png)](https://www.ebay.co.uk/itm/Bell-Wire-Flat-2-Solid-Core-Flexible-Doorbell-Intercom-Phone-Cable-Cut-Lengths/292775619014)
[![Crimping pins](/blog/posts/images/crimp-pins.jpg)](https://www.hobbytronics.co.uk/crimp-conn-pins)
[![Crimp Housing](/blog/posts/images/crimp-housing.jpg)](https://www.hobbytronics.co.uk/crimp-conn-housing-26)


I bought a pre-installed Raspbian SD card as I don't have an SD card
caddy. After some basic configuration (which required HDMI over to a
monitor) I started playing with how to set up the Pi.

Of course the PI is absurdly over-powered for this purpose, but I wanted
something simple to play with. And anyway, it's running Pihole too.

The wiring itself is simple: bell wire over through a hole in the door
frame to the back of the doorbell (which is a simple contact push). The
other end of the wires are connected to the PI's GPIO pin 18, and
ground.
The pin is pulled up and we trigger the event when we see a falling
edge.

Actually connecting the wires was a bit fiddly: the bell wire is too
thin for the 0.1" connector, and lacking a proper crimping tool I had to
bodge it with needle-nose pliers. But once in the pins the housing
connection is solid enough.

At first I tried to connect it to Alexa but soon gave up on that idea.
There's no way to "announce" via any API, and it kept disconnecting when
used as a Bluetooth speaker. And Alexa has that infuriating "Now playing
from..." thing you can't turn off as well.

During fiddling with this I removed PulseAudio from the Pi as a dead
loss.

Nor could I use an Anker Soundcore as a Bluetooth speaker: the stupid
thing has some sleep mode that means it misses off the first 3 seconds
or so of whatever's playing.

Instead I have the crappy USB speaker above. It's not great but is
enough to be heard from outside and inside.

Aside from playing whatever through the speaker, the bell emails me in
case I can't hear it. Here's the somewhat crappy script it's running:

```python
#!/usr/bin/python -u

#
# The Pi is wired up such that pin 18 goes through the switch to ground.
# The on-pin pull-up resistor is enabled (so .input() is normally True).
# When the circuit completes, it goes to ground and hence we get a
# falling edge and .input() becomes False.
#
# I get the occasional phantom still so we wait for settle_time before
# thinking it's real.
#

from email.mime.text import MIMEText
from subprocess import Popen, PIPE
from datetime import datetime
import subprocess
import RPi.GPIO as GPIO
import signal
import time
import os

GPIO.setmode(GPIO.BCM)

GPIO.setup(18, GPIO.IN, pull_up_down=GPIO.PUD_UP)

# in seconds
settle_time = 0.1
bounce_time = 1

def notify():
    print('notifying at %s' % time.time())

    msg = MIMEText("At %s" % datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    msg["From"] = "doorbell <levon@movementarian.org>"
    msg["To"] = "John Levon <john.levon@gmail.com>"
    msg["Cc"] = "John Levon <levon@movementarian.org>"
    msg["Subject"] = "Someone is ringing the doorbell"

    p = Popen(["/usr/sbin/sendmail", "-f", "levon@movementarian.org", "-t", "-oi"], stdin=PIPE)
    p.stdin.write(msg.as_string())
    p.stdin.close()
    while True:
	os.system('aplay -D plughw:1,0 doorbell.wav')
        input_state = GPIO.input(18)
        if input_state:
            break

def settle():
    global settle_time
    time.sleep(settle_time)
    input_state = GPIO.input(18)
    print('input state now %s' % input_state)
    return not input_state

def falling_edge(channel):

    input_state = GPIO.input(18)
    print('got falling edge, input_state %s' % input_state)
    if settle():
        notify()
          
GPIO.add_event_detect(18, GPIO.FALLING, callback=falling_edge, bouncetime=(bounce_time * 1000))

print('started')

signal.pause()
```
