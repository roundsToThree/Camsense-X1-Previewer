# Camsense-X1-Previewer
An app to preview incoming data from the Camsense® X1 LIDAR Scanner.

Copyright (c) 2020 John Sakoutis 
CC BY-SA 3.0 AU

Credit:
Bram Fenijn (https://github.com/vidicon)
J-Fujimoto  (https://github.com/j-fujimoto)

# Setup
After running the application, there if a very high change that it will crash, this is normal as i havent implemented a user interface yet.  
In the folder the program was run in, a document labeled "availablePorts.txt" should have been created after the first failed run, simply find the port you want to use and put it into the first line of the "selected Port.txt" document (example below).

availablePorts.txt should look a bit like this: 
```
/dev/ttyS0  
/dev/ttyS1  
/dev/ttyS2  
/dev/ttyS3  
/dev/ttyUSB0  
```

For example i want to use /dev/ttyUSB0, simply paste /dev/ttyUSB0 into the selectedPort.txt document which should look like this
```
/dev/ttyUSB0
```

Make sure when you are editing these files you use a basic text editor like notepad or nano or vim.  
If you run this program with terminal or command line, debugging information should be printed to the console.

# Operation
Either run the code from the Processing 3 environment or from the premade Windows/MacOS/Linux/linuxArm zips.  
To use the app, note the following keybindings
```
Arrow key left and right for rotation  
Arrow key up / down for scale  
W A S D for moving around  
Z to open the "Shutter" for longer and take in more information  
X to reduce the "Shutter" and take in less information (can caause flickering if its too low but allows for a higher frame rate)  
V to toggle "vector" mode where lines are used instead of dots  
Move the cursor around to get measurements accurate to the 0.1mm  
```

# Planned Updates
*Add an interface for easy setup  
*Optimisations for slower hardware  
*Support for 3D (Placing the Camsense X1 on to a stepper motor and rotating it 180deg so that it gets a full 3D scan)  
*Line recognition so that you can move around with the scanner and it will append to the last scan  
*Exporting to OBJ and Meshroom  
*Vector mode to properly get a feel for the room
