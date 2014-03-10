## EmergencyStripper

This repository contains arduino code and ruby code to interface to the stagger http endpoint, in order to give ambient data about the environment

## Features

- Warns (blue) if no data has been recieved for a while
- Tunes smoothly between red and green as reported error rate goes up

## Hardware:

- Arduino Uno
- 5V, 2A power supply
- http://www.coolcomponents.co.uk/digital-rgb-led-weatherproof-strip-60-led-1m-black.html

## Run as:

- bundle install
- ruby emergency_stripper_interface.rb http://<http endpoint> /dev/tty.usbmodemfd131

## Example:

![Image](../blob/master/example.gif?raw=true)
