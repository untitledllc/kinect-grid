/* --------------------------------------------------------------------------
 * SimpleOpenNI User Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / zhdk / http://iad.zhdk.ch/
 * date:  02/16/2011 (m/d/y)
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;
import fullscreen.*; 

SimpleOpenNI  context;
ArrayList particles;

// every particle within this many pixels will be influenced by the cursor
float mouseInfluenceSize = 20; 
// minimum distance for tearing when user is right clicking
float mouseTearSize = 8;

// force of gravity is really 9.8, but because of scaling, we use 9.8 * 40 (392)
// (9.8 is too small for a 1 second timestep)
float gravity = 0; 

// Dimensions for our curtain. These are number of particles for each direction, not actual widths and heights
// the true width and height can be calculated by multiplying restingDistances by the curtain dimensions
final int k=6;
final int curtainHeight = 14*k;
final int curtainWidth = 24*k;
final int yStart = 50; // where will the curtain start on the y axis?
final float restingDistances = 30/k;
final float stiffnesses = 1.5;
final int curtainTearSensitivity = 100; // distance the particles have to go before ripping
final int maxLenth = 10;
final int scrWidth = 800;
final int scrHeight = 600;

PVector position = new PVector();
PVector screenPos = new PVector();

ArrayList<HandPoint> handPoints = new ArrayList<HandPoint>();
HandPoint leftHand;
HandPoint rightHand;

XnSkeletonJointPosition jointPos;// = new XnSkeletonJointPosition();

IntVector users;// = new IntVector();

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

// Create the fullscreen object
FullScreen fs;


//////////////////ParticleDrower interface 
public static interface ParticleDrower {
  void updatePhysics(Particle particle, float timeStep);
  void updateInteractions(Particle particle);
  void solveConstraints(Particle particle);
  void draw (Particle particle);
}

private ParticleDrower particleDrower;// = new DefaultParticleDrower();

///////////////////////// Setup //////////////////
void setup()
{
  fs = new FullScreen(this); 

  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);

  jointPos = new XnSkeletonJointPosition();
  users = new IntVector();

  // enable depthMap generation 
  context.enableDepth();

  context.setMirror(true);

  // enable skeleton generation for all joints
  context.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);

  background(200, 0, 0);

  strokeWeight(1);
  //smooth();

  //size(context.depthWidth(), context.depthHeight()); 
  // Processing's default renderer is Java2D
  // but we instead use P2D, because it is a lot faster (about 2-3 times faster for me)
  size(scrWidth, scrHeight, P2D);

  previousTime = millis();
  currentTime = previousTime;

  // we square the mouseInfluenceSize and mouseTearSize so we don't have to use squareRoot when comparing distances with this.
  mouseInfluenceSize *= mouseInfluenceSize; 
  mouseTearSize *= mouseTearSize;


  // create the curtain
  createCurtain();

  //set default curtains behavior
  particleDrower = new DefaultParticleDrower();
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
      if (x != 0  && y%k==0) 
        particle.attachTo((Particle)(particles.get(particles.size()-1)), restingDistances, stiffnesses, true);
      // the index for the particles are one dimensions, 
      // so we convert x,y coordinates to 1 dimension using the formula y*width+x  
      if (y != 0  && x%k==0)
        particle.attachTo((Particle)(particles.get((y - 1) * (curtainWidth+1) + x)), restingDistances, stiffnesses, true);

      // we pin the very top particles to where they are
      //      if ( ((y == 0 && x == 0) || (x == curtainWidth && y == curtainHeight)) 
      //     ||( (y == 0 && x == curtainWidth) || (y == curtainHeight &&  x == 0 )) )
      if (y == 0 || x == 0 || x == curtainWidth || y == curtainHeight) 
        particle.pinTo(particle.position);


      // add to particle array  
      particles.add(particle);
    }
  }
}


void draw()
{
  // update the cam
  context.update();

  // draw depthImageMap
  image(context.depthImage(), 0, 0, scrWidth, scrHeight);

  context.getUsers(users);

  // draw the skeleton if it's available
  if (users.size()>0 && context.isTrackingSkeleton(users.get(0)) )
    drawSkeleton(users.get(0));

  // Move origin to center of the screen.
  translate(width/2, height/2);


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
        particleDrower.solveConstraints(particle);
      }
    }

    // update each particle's position
    for (int i = 0; i < particles.size(); i++) {
      Particle particle = (Particle) particles.get(i);
      particleDrower.updatePhysics(particle, fixedDeltaTimeSeconds); // the physics works in seconds, so fixedDeltaTime is divided by 1000
    }
  }


  // we use a separate loop for drawing so points and their links don't get drawn more than once
  // (rendering can be a major resource hog if not done efficiently)
  // also, interactions (mouse dragging) is applied
  strokeWeight(1);
  for (int i = 0; i < particles.size(); i++) {
    Particle particle = (Particle) particles.get(i);
    particleDrower.updateInteractions(particle);   
    particleDrower.draw(particle);
  }

  if (frameCount % 30 == 0)
    println("Frame rate is " + frameRate);

  //  if (millis() < instructionLength)
  //    drawInstructions();
}


// Controls. The r key resets the curtain, g toggles gravity
void keyPressed() {
  if ((key == 'r') || (key == 'R'))
    createCurtain();
  if ((key == 'g') || (key == 'G'))
    toggleGravity();    
  // enter fullscreen mode
  if ((key == 'f') || (key == 'F'))
    toggleFullScreen();
  if ( (key == '1') &&  !(particleDrower instanceof DefaultParticleDrower) )
    particleDrower = new DefaultParticleDrower();
  if (key == '2' &&  !(particleDrower instanceof HardParticleDrower) )
    particleDrower = new HardParticleDrower();
  switch(key)
  {
  case 'e':
    // end sessions
    // sessionManager.EndSession();
    println("end session");
    break;
  }
}

void toggleFullScreen () {
  if (fs.isFullScreen()) {
    // size(scrWidth, scrHeight);
    fs.leave();
  }

  else {
    fs.enter();
    //size(scrWidth, scrHeight);
  }
}

void toggleGravity () {
  if (gravity != 0)
    gravity = 0;
  else
    gravity = 392;
}

void saveUser() {
  context.getUsers(users);

  // draw the skeleton if it's available
  if (users.size()>0 && context.isTrackingSkeleton(users.get(0)) ) {
    if (context.saveCalibrationDataSkeleton(users.get(0), 1))
      println("Calibration data saved for userId: " + users.get(0)); 
    else  
      println("ERROR saving calibration data for userId: " + users.get(0));
  }
}

void loadUser() {

  if (context.loadCalibrationDataSkeleton(1, 1)) {
    context.startTrackingSkeleton(1);
    println("Calibration data loaded for userId: " + 1);
  }
  else  
    println("ERROR loading calibration data for userId: " + 1);
}

// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  handPoints.clear();
  if (leftHand == null) 
    leftHand = new HandPoint();

  if (rightHand == null) 
    rightHand = new HandPoint();

  strokeWeight(10);
  stroke(255, 0, 0);

  if (context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, jointPos)) {
    position.set(jointPos.getPosition().getX(), jointPos.getPosition().getY(), jointPos.getPosition().getZ());
    context.convertRealWorldToProjective(position, screenPos);
    leftHand.nextPos(new PVector((int)screenPos.x*scrWidth/640, (int)screenPos.y*scrHeight/480));
    handPoints.add(leftHand);
    point((int)screenPos.x*scrWidth/640, (int)screenPos.y*scrHeight/480);
  }


  if (context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, jointPos)) {
    position.set(jointPos.getPosition().getX(), jointPos.getPosition().getY(), jointPos.getPosition().getZ());
    context.convertRealWorldToProjective(position, screenPos);
    rightHand.nextPos(new PVector((int)screenPos.x*scrWidth/640, (int)screenPos.y*scrHeight/480));
    handPoints.add(rightHand);
    point((int)screenPos.x*scrWidth/640, (int)screenPos.y*scrHeight/480);
  }

  // to get the 3d joint data
  /*
  PVector jointPos = new PVector();
   context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,jointPos);
   println(jointPos);
   */
  /*  
   context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
   
   context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
   context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
   context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);
   
   context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
   context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
   context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);
   */

  /*
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
   context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
   
   context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
   context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
   context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);
   
   context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
   context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
   context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
   
   */
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(int userId)
{
  println("onNewUser - userId: " + userId);
  if (context.loadCalibrationDataSkeleton(userId, 1)) {
    context.startTrackingSkeleton(userId); 
    println("Calibration data loaded for userId: " + userId);
  }
  else {
    println("  start pose detection");
    context.startPoseDetection("Psi", userId);
  }
}

void onLostUser(int userId)
{
  println("onLostUser - userId: " + userId);
}

void onStartCalibration(int userId)
{
  println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
  println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);

  if (successfull) 
  { 
    println("  User calibrated !!!");
    context.startTrackingSkeleton(userId); 
    if (context.saveCalibrationDataSkeleton(userId, 1))
      println("Calibration data saved for userId: " + userId); 
    else  
      println("ERROR saving calibration data for userId: " + userId);
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
    println("  Start pose detection");
    context.startPoseDetection("Psi", userId);
  }
}

void onStartPose(String pose, int userId)
{
  println("onStartPose - userId: " + userId + ", pose: " + pose);
  println(" stop pose detection");

  context.stopPoseDetection(userId); 
  if (context.loadCalibrationDataSkeleton(userId, 1)) {
    context.startTrackingSkeleton(userId); 
    println("Calibration data loaded for userId: " + userId);
  }
  else
    context.requestCalibrationSkeleton(userId, true);
}

void onEndPose(String pose, int userId)
{
  println("onEndPose - userId: " + userId + ", pose: " + pose);
}

