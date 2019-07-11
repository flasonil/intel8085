# intel8085

https://www.slideshare.net/SrikrishnaThota/8085-interfacing-with-memory-chips-58311824

I am trying to develop an Intel 8085 ISA compatible CPU together with peripherals such as memories and I/Os.
The cpu in the master branch does not contain a control unit. Each instruction has a flag which are properly set in the opcode fetch machine cycle and handle all the internal microperations.
In the branch I am instead trying to add a control unit with a small microcoded ROM. So far I have managed to microcode MOV B E .
