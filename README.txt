Version: v1.0
Type: Master Commit
Message:
Added drivers for I2C communication.
Added drivers for left justified communication (similar to I2S but left justified by 1 bit) between WM8731 and FPGA.
Interfaced LINEIN and LINEOUT.
Added volume control and mute functionality.
Mapped volume control to LEDs.
Button frequency (volume control)  matched with audio driver frequency.

Version: v2.0
Type: Major Update
Message:
Added NIOS PIO components for bass and treble switches, JTAG, SRAM and NIOS Processor.
Added software section to be able to write in C.
Added First Order Low Pass IIR filter for Bass filtering on software.
Added High Pass Filter for Treble filtering on software.
Added three stage intensity for Bass
Added three stage filtering for Treble.

Version: v2.1
Type: Minor Update
Message:
Removed old commented code.
Added commented code only to check raw data.
