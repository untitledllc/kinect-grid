/* 
  Curtain (Fabric Simulator)
  Made by BlueThen on February 5th, 2011; updated February 10th and 11th, 2011
  To interact, left click and drag, right click to tear, 
               press 'G' to toggle gravity, and press 'R' to reset
  www.bluethen.com
*/

ArrayList particles;

// every particle within this many pixels will be influenced by the cursor
float mouseInfluenceSize = 30; 
// minimum distance for tearing when user is right clicking
float mouseTearSize = 8;

// force of gravity is really 9.8, but because of scaling, we use 9.8 * 40 (392)
// (9.8 is too small for a 1 second timestep)
float gravity = 392; 

// Dimensions for our curtain. These are number of particles for each direction, not actual widths and heights
// the true width and height can be calculated by multiplying restingDistances by the curtain dimensions
final int curtainHeight = 40;
final int curtainWidth = 70;
final int yStart = 5; // where will the curtain start on the y axis?
final float restingDistances = 10;
final float stiffnesses = 1;
final int curtainTearSensitivity = 100; // distance the particles have to go before ripping

// These variables are used to keep track of how much time is elapsed between each frame
// they're used in the physics to maintain a certain level of accuracy and consistency
// this program should run the at the same rate whether it's running at 30 FPS or 300,000 FPS
long previousTime;
long currentTime;
// Delta means change. It's actually a triangular symbol, to label variables in equations
// some programmers like to call it elapsedTime, or changeInTime. It's all a matter of preference
// To keep the simulation accurate, we use a fixed time step.
final int fixedDeltaTime = 25;
float fixedDeltaTimeSeconds = (float)fixedDeltaTime / 1000;
// the leftOverDeltaTime carries over change in time that isn't accounted for over to the next frame
int leftOverDeltaTime = 0;

// instructional stuffs:
PFont font;
final int instructionLength = 3000;
final int instructionFade = 300;
void setup () {
  // Processing's default renderer is Java2D
  // but we instead use P2D, because it is a lot faster (about 2-3 times faster for me)
  size(800,600, P2D);
  
  previousTime = millis();
  currentTime = previousTime;
  
  // we square the mouseInfluenceSize and mouseTearSize so we don't have to use squareRoot when comparing distances with this.
  mouseInfluenceSize *= mouseInfluenceSize; 
  mouseTearSize *= mouseTearSize;
  
  // create the curtain
  createCurtain();
  
  //font = loadFont("LucidaBright-Demi-16.vlw");
  //textFont(font);
}

void draw () {
  background(255);
  // Move origin to center of the screen.
  translate(width/2,height/2);
 
  
  /******** Physics ********/
  // time related stuff
  currentTime = millis();
  // deltaTimeMS: change in time in milliseconds since last frame
  long deltaTimeMS = currentTime - previousTime;
  previousTime = currentTime; // reset previousTime
  // timeStepAmt will be how many of our fixedDeltaTime's can fit in the physics for this frame. 
  int timeStepAmt = (int)((float)(deltaTimeMS + leftOverDeltaTime) / (float)fixedDeltaTime);
  leftOverDeltaTime = (int)deltaTimeMS - (timeStepAmt * fixedDeltaTime); // reset leftOverDeltaTime.
  float fixedDeltaTimeSeconds = (float)fixedDeltaTime / 1000;
  // update physics
  for (int iteration = 1; iteration <= timeStepAmt; iteration++) {
    // solve the constraints 3 times.
    for (int x = 0; x < 3; x++) {
      for (int i = 0; i < particles.size(); i++) {
        Particle particle = (Particle) particles.get(i);
        particle.solveConstraints();
      }
    }
    
    // update each particle's position
    for (int i = 0; i < particles.size(); i++) {
      Particle particle = (Particle) particles.get(i);
      particle.updatePhysics(fixedDeltaTimeSeconds); // the physics works in seconds, so fixedDeltaTime is divided by 1000
    }
  }
  
  
  // we use a separate loop for drawing so points and their links don't get drawn more than once
  // (rendering can be a major resource hog if not done efficiently)
  // also, interactions (mouse dragging) is applied
  for (int i = 0; i < particles.size(); i++) {
    Particle particle = (Particle) particles.get(i);
    particle.updateInteractions();
    particle.draw();
  }
  
  if (frameCount % 30 == 0)
    println("Frame rate is " + frameRate);
  
  if (millis() < instructionLength)
    drawInstructions();
}
void createCurtain () {
  // We use an ArrayList instead of an array so we could add or remove particles at will.
  // not that it isn't possible using an array, it's just more convenient this way
  particles = new ArrayList();
  
  int midWidth = (int) curtainWidth / 2; // we use this to center our curtain
  // Since this our fabric is basically a grid of points, we have two loops
  for (int y = 0; y <= curtainHeight; y++) { // due to the way particles are attached, we need the y loop on the outside
    for (int x = 0; x <= curtainWidth; x++) { 
      Particle particle = new Particle(new PVector((x - midWidth) * restingDistances, y * restingDistances - height/2 + yStart));
      
      // attach to 
      // x - 1  
      // y - 1  
      // particle attachTo parameters: Particle particle, float restingDistance, float stiffness, boolean drawThis
      // try disabling the next 2 lines (the if statement and attachTo part) to create a hairy effect
      if (x != 0) 
        particle.attachTo((Particle)(particles.get(particles.size()-1)), restingDistances, stiffnesses, true);
      // the index for the particles are one dimensions, 
      // so we convert x,y coordinates to 1 dimension using the formula y*width+x  
      if (y != 0)
        particle.attachTo((Particle)(particles.get((y - 1) * (curtainWidth+1) + x)), restingDistances, stiffnesses, true);
        
/*
      // shearing, presumably. Attaching invisible links diagonally between points can give our cloth stiffness.
      // the stiffer these are, the more our cloth acts like jello. 
      // these are unnecessary for me, so I keep them disabled.
      if ((x != 0) && (y != 0)) 
        particle.attachTo((Particle)(particles.get((y - 1) * (curtainWidth+1) + (x-1))), restingDistances * sqrt(2), 0.1, false);
      if ((x != curtainWidth) && (y != 0))
        particle.attachTo((Particle)(particles.get((y - 1) * (curtainWidth+1) + (x+1))), restingDistances * sqrt(2), 1, true);
*/
      
      // we pin the very top particles to where they are
      if (y == 0 || x == 0 || x == curtainWidth || y == curtainHeight)
        particle.pinTo(particle.position);
        

      // add to particle array  
      particles.add(particle);
    }
  }
}

// Controls. The r key resets the curtain, g toggles gravity
void keyPressed() {
  if ((key == 'r') || (key == 'R'))
    createCurtain();
  if ((key == 'g') || (key == 'G'))
    toggleGravity();
}
void toggleGravity () {
  if (gravity != 0)
    gravity = 0;
  else
    gravity = 392;
}

void drawInstructions () {
  float fade = 255 - (((float)millis()-(instructionLength - instructionFade)) / instructionFade) * 255;
  stroke(0, fade);
  fill(255, fade);
  rect(-width/2,-height/2, 200,45);
  fill(0, fade);
  text("'r' : reset", -width/2 + 10, -height/2 + 20);
  text("'g' : toggle gravity", -width/2 + 10, -height/2 + 35);
}
