# Raspberry Pi Simulink Driver for AD7705

[![View Raspberry Pi Simulink Driver for AD7705 on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://jp.mathworks.com/matlabcentral/fileexchange/78420-raspberry-pi-simulink-driver-for-ad7705)

## Overview
This model makes it possible to log data from AD7705 using Raspberry Pi on Simulink. This model simply reads the binary data from the AD7705. Add post-processing blocks as needed. For example, filtering.

## Requires
* Simulink Support Package for Raspberry Pi Hardware

## Compatibility
Created with
* MATLAB R2020a
* Raspberry Pi 3B+ / 4B

## How to use
### Wiring

| Raspberry Pi | AD7705 | Measuring object |
----|----|----
| 3v3 Power | VCC | Power |
| Ground | GND | Ground |
| CE0 (BCM 8) / CE1 (BCM 7)<br>CE2 (BCM 6) / CE3 (BCM 5) **| CS | - |
| - | RST | - | - |
| MOSI (BCM 10) | DIN | - |
| SCLK (BCM 11) | SCK | - |
| - | DRDY | - |
| MISO (BCM 9) | DOUT | - |
| - | AN1+ / AN2+ | Output |
| - | AN1- / AN2- | (Ground) |

** Modification of Device Trees is required to use CE2 and CE3. (Addition of SPI CE ports)

### Getting started
1. Open the "Sample.slx" model.

2. Double-click the "AD7705" block to open the "block parameter". You need to set the parameters. Refer to the following page (P.16 - 19).

   [AD7705/AD7706 - Analog Devices](https://www.analog.com/media/en/technical-documentation/data-sheets/AD7705_7706.pdf)

3. Open the model's "*configuration parameters*" and change settings as needed. For example, Device Address, Username, etc. (The SPI communication speed setting is not reflected.)

4. Click "*Monitor & tune*" on the model's "*Hardware*" tab to start logging. In default model, you will see and log binary data on the scope block.

5. Add a post-processing block as needed.

### Addition of SPI CE ports

Normally Raspberry Pi supports only 2 CE ports with SPI0. However, you can increase the number of CE ports to 4 by the following procedure.<br>*If you do not perform this procedure, only CE0 and CE1 ports can be used. Do not use the CE2 and CE3 ports.*

1. Copy *spi0-4cs-overlay.dts* in *dts* folder to Raspberry Pi.

2. Enter the following command to compile the file. Then copy the generated file to */boot/overlays*.

   ```
   $ dtc -@ -I dts -O dtb -o spi0-4cs.dtbo spi0-4cs-overlay.dts
   $ sudo cp spi0-3cs.dtbo /boot/overlays
   ```

3. Lanch nano and edit */boot/config.txt*. And reboot the Raspberry Pi.
   ```
   $ sudo nano /boot/config.txt
   ```
   Add the following to the last line.
   ```
   #Enable SPI0 CE2 and CE3
   dtoverlay=spi0-4cs
   ```
   Save the file and reboot.
   ```
   $ sudo reboot
   ```

4. Check if the new SPI CE ports have been added. If `spidev0.2` and `spidev0.3` are added, the work is successful.
   ```
   $ ls /dev/spi*
   /dev/spidev0.0  /dev/spidev0.1  /dev/spidev0.2  /dev/spidev0.3
   ```

### Implementation in your model
Copy the "AD7705" block to your model. And, place the "src", "include" folders and "AD7705RasPi.m" on your model path.

### Using for Load cells
The AD7705 has a PGA (programmable gain amplifier) ​​with a programmable gain of **1 to 128** times. It is perfect for use with load cells. Unfortunately, the inexpensive AD7705 board available from amazon etc. cannot be used as is for load cell measurements. However, you can make it measurable by the following procedure.

* Make analog inputs differential\
  This task is mandatory. Prepare a soldering iron with a sharp tip.

  * To make **AIN1** differential, **remove** the chip resistor of **R7**.
  * To make **AIN2** differential, **remove** the chip resistor of **R9**.


* Adjust the input impedance\
  This task is optional.

  * For matching impedance of **AIN1**, **remove** the chip resistors of **R3** and **R4**, and **short R3**.
  * For matching impedance of **AIN2**, **remove** the chip resistors of **R2** and **R5**, and **short R2**.
  * Insert and connect an appropriate resistor between the load cell and AIN. Generally, insert a resistor of about 100 ohms.

## Limitation
* The number of CE ports of SPI

  Up to 2 AD7705 boards can be connected at the same time. You can add up to 4 by modifying Device Trees. Detail -> Addition of SPI CE ports\
  Also for reference, AD7705 communicates with SPI mode 3, but the extended SPI (SPI1, 2...) function of Raspberry Pi supports only mode 0 and mode 2. Therefore the AD7705 can only operate on SPI0.

* The number of usable analog ports

  The AD7705 has AIN1 and AIN2 of 2 analog inputs. However, shares the A/D converter inside the chip. Switching between these channels can take up to 4 times the conversion rate. Therefore, it is virtually impossible to use 2 channels for real-time processing. This Simulink driver only supports either AIN1 or AIN2.

  Reference : [AD7705/AD7706/AD7707 Instrumentation ConverterFAQs: Analog Performance](https://www.analog.com/media/cn/technical-documentation/frequently-asked-questions/AD7705_6_7_ANALOG_PERFORMANCE.pdf)
