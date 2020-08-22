/*
Camsense® X1 Previewer
V1.2
An app to preview incoming data from the Camsense® X1 LIDAR Scanner.

Copyright John Sakoutis 2020
CC BY-SA 3.0 AU


Credit:
Bram Fenijn (https://github.com/vidicon)
J-Fujimoto  (https://github.com/j-fujimoto)
*/



import processing.serial.*;

Serial lidarPort;  // Create object from Serial class
int val;      // Data received from the serial port

PVector[] log = {};

int logSize = 480;
boolean writeInProg = false;
float scale = 7;
float thetaOffset = 0;
float tx = 0;
float ty = 0;
void setup() 
{
  //Make log array
  log = new PVector[logSize];
  //Set the frame rate
  frameRate(140);

  //Set to fullScreen (Uncomment for fullscreen)
  //fullScreen();

  //Make resizable (Comment next two lines for fullscreen)
  surface.setResizable(true);
  size(800, 600);

  saveStrings("avilablePorts.txt", Serial.list());
  String port = "";
  try {
    port = loadStrings("selectedPort.txt")[0];
  }
  catch(Exception e) {
    println(e, "Make sure that the port is correctly stated in selectedPort.txt");
    println("See availablePorts.txt, find the desired port and write it in selectedPort.txt in a basic text editor (line endings may affect the outcome)");
  }

  //Purify entry and initiate Serial Port
  String tmpPort = "";
  for (int i = 0; i < port.length(); i ++) {
    if (char(port.charAt(i)) >= 32 && char(port.charAt(i)) <= 122) // Only allow printable characters
      tmpPort += port.charAt(i);
  }

  try {
    lidarPort = new Serial(this, tmpPort, 115200);
  }
  catch(Exception e) {
    println(e, "The port name may either be invalid or contain non printable ascii characters, change the line endings of selectedPort.txt and try again", "If this continues, check to make sure that you have enabled the usb port/given it appropriate permissions");
  }


  //Begin thread that scans for new data
  thread("threaded");
}


//Manage key presses
/*
Arrow key left and right for rotation
 Arrow key up / down for scale
 W A S D for moving around
 Z to open the "Shutter" for longer and take in more information
 X to reduce the "Shutter" and take in less information (can caause flickering if its too low but allows for a higher frame rate)
 V to toggle "vector" mode where lines are used instead of dots
 
 */
void keyPressed() {
  if (keyCode == RIGHT)
    thetaOffset += 0.05;
  if (keyCode == LEFT)
    thetaOffset -= 0.05;
  if (keyCode == UP)
    scale += 0.1;
  if (keyCode == DOWN)
    scale -= 0.1;
  if (key == 'a')
    tx -= 2;
  if (key == 'd')
    tx += 2;
  if (key == 'w')
    ty += 2;
  if (key == 's')
    ty -= 2 ;


  //"Vector" mode
  if (key == 'v')
    vector = !vector;
}

boolean packetAligned = false;
boolean vector = false;

void draw()
{
  //In draw loop for finer control
  if (keyPressed) {
    //Psuedo Apeture
    if (key == 'z')
      logSize = constrain(logSize + 5, 0, 10000);
    if (key == 'x')
      logSize = constrain(logSize - 5, 0, 10000);
  }

  //Move the canvas around from wasd control
  translate(tx, ty);

  //Set styles
  background(255);

  //Create centre point for lidar scanner
  stroke(0, 255, 0);
  noFill();
  ellipse(width/2, height/2, 10, 10);

  //Curser distance
  text(float(nf(int(10*pow(pow((width/2 - mouseX + tx)*scale, 2) + pow((height/2 - mouseY + ty)*scale, 2), .5)), 4))/10 + "mm", mouseX - tx, mouseY - ty);
  fill(0);

  //Either psudo vector draw or point draw
  if (vector) {
    stroke(0);

    //Future Update here: Sort array first and then make lines, this allows lines to be carried across from each loop
    for (int i = 1; i < log.length; i++) {
      if (log[i-1] != null && log[i] != null) {

        //if the distance between two points is less than 10, draw a line in between
        if (dist(log[i-1].x, log[i-1].y, log[i].x, log[i].y) < 10)
          line(log[i-1].x, log[i-1].y, log[i].x, log[i].y);
        else {
          point(log[i].x, log[i].y);
        }
      }
    }
  } else {
    noStroke();

    for (int i = 0; i < log.length; i++) {
      if (log[i] != null) {
        ellipse(log[i].x, log[i].y, 3, 3);
      }
    }
  }
}

//Function to get a byte (2*chars) in packet to make the code later on less complicated 
String getByte(String packet, int b) {
  return packet.substring(b*2, (b+1)*2);
}


//Threaded loop
void threaded() {
  while (true)
    getAndProcess();
}


void getAndProcess() {
  if ( lidarPort.available() > 1024) {
    println("System cant keep up! more than 1KiB of data is waiting to be processed:", lidarPort.available());
  }
  
  if ( lidarPort.available() > 35) {  // If data is available, (36 is the packet size after alignment) I actually had this at 31 before and i cant remember why becasuse i wrote this a week ago
    String packet = "";
    for (int i = 0; i < 36; i++) {
      val = lidarPort.read();         // read it and store it in val
      packet += hex(val, 2);
    }

    if (!packetAligned) {
      //AUTO ALIGN PACKET
      //Scan packet to align the startpacket 
      String tmppacket = packet + packet;
      //println(tmppacket);
      int packetsToDiscard = tmppacket.indexOf("55AA0308")/2; //Start packet
      //print(packetsToDiscard, 36*2); //Start byte (number of packets to discard for next time around
      while (lidarPort.available() < packetsToDiscard);
      for (int i = 0; i < packetsToDiscard; i++) {
        lidarPort.read();
      }
      packetAligned = false; //Set to false to make sure packets are aligned each revolution, Set to true to align packet at beginning (faster)
    }
    //Thanks to Vidicon https://github.com/vidicon and Fujimoto https://github.com/j-fujimoto/CamsenseX1 for these numbers
    //Before i didn't realise it was little endian and deg. rather than radians
    float startAngle = (unhex(getByte(packet, 7) + getByte(packet, 6))- 40960)/64; 
    float endAngle = (unhex(getByte(packet, 33) + getByte(packet, 32))- 40960)/64;
    
    //If ended after a revolution but started before a revolution finished, this fixes it
    //DOES NOT ACCOUNT IF THE LIDAR IS GOING LESS THAN 1RPM
    if (endAngle < startAngle) {
      endAngle += 360;
    }
    for (int i = 0; i < 8; i++) {

      float theta = (startAngle + i*(endAngle - startAngle)/8)*PI/180 + thetaOffset; //thetaOffset purely visual (left and right keys control this)
      float distance =  unhex(getByte(packet, 9+3*i) + getByte(packet, 8+3*i));
      
      //Convert polar coordinates to cartesian coordinates
      float x = distance * cos(theta);
      float y = distance * sin(theta);

      //Add points to the running log
      
      //Push all points in log down by one and remove the last entry, then add the new point in the beginning
      //This can be a bit slow, should use arrayList next time?
      log = (PVector[])append(log, new PVector(x/scale + width/2, y/scale + height/2));
      if (log.length > logSize) {
        for (int l = 1; l < log.length; l++) {
          log[l-1] = log[l];
        }
        while (log.length > logSize)
          log = (PVector[])shorten(log);
      }

     
    }
  }
}
