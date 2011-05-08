import processing.core.*; 
import processing.xml.*; 

import SimpleOpenNI.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class OpenProcessingSketch extends PApplet {


// The Link class is used for handling constraints between particles.
class Link {
  float restingDistance;
  float stiffness;
  
  Particle p1;
  Particle p2;
  
  // the scalars are how much "tug" the particles have on each other
  // this takes into account masses and stiffness, and are set in the Link constructor
  float scalarP1;
  float scalarP2;
  
  // if you want this link to be invisible, set this to false
  boolean drawThis;
  
  Link (Particle which1, Particle which2, float restingDist, float stiff, boolean drawMe) {
    p1 = which1; // when you set one object to another, it's pretty much a reference. 
    p2 = which2; // Anything that'll happen to p1 or p2 in here will happen to the paticles in our array
    
    restingDistance = restingDist;
    stiffness = stiff;
    
    // although there are no differences in masses for the curtain, 
    // this opens up possibilities in the future for if we were to have a fabric with particles of different weights
    float im1 = 1 / p1.mass; // inverse mass quantities
    float im2 = 1 / p2.mass;
    scalarP1 = (im1 / (im1 + im2)) * stiffness;
    scalarP2 = (im2 / (im1 + im2)) * stiffness;
    
    drawThis = drawMe;
  }
  
  public void constraintSolve () {
    // calculate the distance between the two particles
    PVector delta = PVector.sub(p1.position, p2.position);  
    float d = sqrt(delta.x * delta.x + delta.y * delta.y);
    float difference = (restingDistance - d) / d;
    
    // if the distance is more than curtainTearSensitivity, the cloth tears
    // it would probably be better if force was calculated, but this works
    //if (d > curtainTearSensitivity) 
      //p1.removeLink(this);
    
    // P1.position += delta * scalarP1 * difference
    // P2.position -= delta * scalarP2 * difference
    p1.position.add(PVector.mult(delta, scalarP1 * difference));
    p2.position.sub(PVector.mult(delta, scalarP2 * difference));
  }
}
// the Particle class.
class Particle {
  PVector lastPosition; // for calculating position change (velocity)
  PVector position;

  PVector acceleration; 

  float mass = 1;
  float damping = 20; // friction

  // An ArrayList for links, so we can have as many links as we want to this particle :)
  ArrayList links = new ArrayList();

  boolean pinned = false;
  PVector pinLocation = new PVector(0, 0);

  // Particle constructor
  Particle (PVector pos) {
    position = pos.get();
    lastPosition = pos.get();
    acceleration = new PVector(0, 0);
  }

  // The update function is used to update the physics of the particle.
  // motion is applied, and links are drawn here
  public void updatePhysics (float timeStep) { // timeStep should be in elapsed seconds (deltaTime)
    // gravity:
    // f(gravity) = m * g
    PVector fg = new PVector(0, mass * gravity);
    this.applyForce(fg);

    /* Verlet Integration, WAS using http://archive.gamedev.net/reference/programming/features/verlet/ 
     however, we're using the tradition Velocity Verlet integration, because our timestep is now constant. */
    // velocity = position - lastPosition
    PVector velocity = PVector.sub(position, lastPosition);
    // apply damping: acceleration -= velocity * (damping/mass)
    acceleration.sub(PVector.mult(velocity, damping/mass)); 
    // newPosition = position + velocity + 0.5 * acceleration * deltaTime * deltaTime
    PVector nextPos = PVector.add(PVector.add(position, velocity), PVector.mult(PVector.mult(acceleration, 0.5f), timeStep * timeStep));
    // reset variables
    lastPosition.set(position);
    position.set(nextPos);
    acceleration.set(0, 0, 0);


    // make sure the particle stays in its place if it's pinned
    if (pinned)
      position.set(pinLocation);
  } 
  /*  void updateInteractions () {
   
   // this is where our interaction comes in.
   if (mousePressed) {
   float distanceSquared = sq(mouseX-width/2 - position.x) + sq(mouseY-height/2 - position.y);
   if (mouseButton == LEFT) {
   if (distanceSquared < mouseInfluenceSize) { // remember mouseInfluenceSize was squared in setup()
   // move particles towards where the mouse is moving
   // amount to add onto the particle position:
   PVector addition = new PVector((mouseX - pmouseX),
   (mouseY - pmouseY));
   position.add(addition);
   // lastPosition = (lastPosition + position*2) / 3
   // we * 2 and / 3 so the particle is more influenced by mouse dragging
   lastPosition.set(PVector.div(PVector.add(lastPosition,PVector.mult(position,2)),3));
   }
   }
   else { // if the right mouse button is clicking, we tear the cloth by removing links
   if (distanceSquared < mouseTearSize) 
   links.clear();
   }
   }
   }*/

  public void updateInteractions (PVector m) {

    // this is where our interaction comes in.

    //float distanceSquared = sq(cX-width/2 - position.x) + sq(cY-height/2 - position.y);

    //if (distanceSquared < mouseInfluenceSize) { // remember mouseInfluenceSize was squared in setup()
      // move particles towards where the mouse is moving
      // amount to add onto the particle position:
     
      position.add(m);
      // lastPosition = (lastPosition + position*2) / 3
      // we * 2 and / 3 so the particle is more influenced by mouse dragging
      lastPosition.set(PVector.div(PVector.add(lastPosition, PVector.mult(position, 2)), 3));
   // }
  }

  public void draw () {
    // draw the links and points
    stroke(0);
    if (links.size() >  0) {
      for (int i = 0; i <  links.size(); i++) {
        Link currentLink = (Link) links.get(i);
        if (currentLink.drawThis) // some links are invisible
          line(position.x, position.y, currentLink.p2.position.x, currentLink.p2.position.y);
      }
    }
    else
      point(position.x, position.y);
  }
  // here we tell each Link to solve constraints
  public void solveConstraints () {
    for (int i = 0; i <  links.size(); i++) {
      Link currentLink = (Link) links.get(i);
      currentLink.constraintSolve();
    }
    // These if statements keep the particles within the screen
    if (position.y <  -height/2+1)
      position.y = 2 * (-height/2 + 1) - position.y;
    if (position.y >  height/2-1)
      position.y = 2 * (height/2 - 1) - position.y;
    if (position.x >  width/2-1)
      position.x = 2 * (width/2 - 1) - position.x;
    if (position.x <  -width/2+1)
      position.x = 2 * (-width/2 + 1) - position.x;
  }

  // attachTo can be used to create links between this particle and other particles
  public void attachTo (Particle P, float restingDist, float stiff, boolean drawThis) {
    Link lnk = new Link(this, P, restingDist, stiff, drawThis);
    links.add(lnk);
  }
  public void removeLink (Link lnk) {
    links.remove(lnk);
  }  

  public void applyForce (PVector f) {
    // acceleration = (1/mass) * force
    // or
    // acceleration = force / mass
    acceleration.add(PVector.div(PVector.mult(f, 1), mass));
  }

  public void pinTo (PVector location) {
    pinned = true;
    pinLocation.set(location);
  }
} 

/* 
 Curtain (Fabric Simulator)
 Made by BlueThen on February 5th, 2011; updated February 10th and 11th, 2011
 To interact, left click and drag, right click to tear, 
 press 'G' to toggle gravity, and press 'R' to reset
 www.bluethen.com
 */





SimpleOpenNI      context;

// NITE
XnVSessionManager sessionManager;
XnVFlowRouter     flowRouter;

PointDrawer       pointDrawer;


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
final int k=4;
final int curtainHeight = 14*k;
final int curtainWidth = 24*k;
final int yStart = 5; // where will the curtain start on the y axis?
final float restingDistances = 5;
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
public void setup () {
  // Processing's default renderer is Java2D
  // but we instead use P2D, because it is a lot faster (about 2-3 times faster for me)
  size(800, 600);

  previousTime = millis();
  currentTime = previousTime;

  // we square the mouseInfluenceSize and mouseTearSize so we don't have to use squareRoot when comparing distances with this.
  mouseInfluenceSize *= mouseInfluenceSize; 
  mouseTearSize *= mouseTearSize;

  // create the curtain
  createCurtain();

  //font = loadFont("LucidaBright-Demi-16.vlw");
  //textFont(font);

  context = new SimpleOpenNI(this);

  // mirror is by default enabled
  context.setMirror(true);

  // enable depthMap generation 
  context.enableDepth();

  // enable the hands + gesture
  context.enableGesture();
  context.enableHands();

  // setup NITE 
  sessionManager = context.createSessionManager("Click,Wave", "RaiseHand");

  pointDrawer = new PointDrawer();
  flowRouter = new XnVFlowRouter();
  flowRouter.SetActive(pointDrawer);

  sessionManager.AddListener(flowRouter);

  size(context.depthWidth(), context.depthHeight()); 
  smooth();
}

public void draw () {

  background(200, 0, 0);
  // update the cam
  context.update();

  // update nite
  context.update(sessionManager);

  // draw depthImageMap
  image(context.depthImage(), 0, 0);



  //background(255);
  // Move origin to center of the screen.
  translate(width/2, height/2);






  // draw the list
  pointDrawer.draw();



  if (frameCount % 30 == 0)
    println("Frame rate is " + frameRate);

  if (millis() <  instructionLength)
    drawInstructions();
}
public void createCurtain () {
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
      if (y == 0)// || x == 0 || x == curtainWidth || y == curtainHeight)
        particle.pinTo(particle.position);


      // add to particle array  
      particles.add(particle);
    }
  }
}

// Controls. The r key resets the curtain, g toggles gravity
public void keyPressed() {
  if ((key == 'r') || (key == 'R'))
    createCurtain();
  if ((key == 'g') || (key == 'G'))
    toggleGravity();
  switch(key)
  {
  case 'e':
    // end sessions
    sessionManager.EndSession();
    println("end session");
    break;
  }
}
public void toggleGravity () {
  if (gravity != 0)
    gravity = 0;
  else
    gravity = 392;
}

public void drawInstructions () {
  float fade = 255 - (((float)millis()-(instructionLength - instructionFade)) / instructionFade) * 255;
  stroke(0, fade);
  fill(255, fade);
  rect(-width/2, -height/2, 200, 45);
  fill(0, fade);
  text("'r' : reset", -width/2 + 10, -height/2 + 20);
  text("'g' : toggle gravity", -width/2 + 10, -height/2 + 35);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
// session callbacks

public void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}

public void onEndSession()
{
  println("onEndSession: ");
}

public void onFocusSession(String strFocus, PVector pos, float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// PointDrawer keeps track of the handpoints

class PointDrawer extends XnVPointControl
{
  HashMap    _pointLists;
  int        _maxPoints;
  int[]    _colorList = { 
    color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0)
  };

  public PointDrawer()
  {
    _maxPoints = 30;
    _pointLists = new HashMap();
  }

  public void OnPointCreate(XnVHandPointContext cxt)
  {
    // create a new list
    addPoint(cxt.getNID(), new PVector(cxt.getPtPosition().getX(), cxt.getPtPosition().getY(), cxt.getPtPosition().getZ()));

    println("OnPointCreate, handId: " + cxt.getNID());
  }

  public void OnPointUpdate(XnVHandPointContext cxt)
  {
    //println("OnPointUpdate " + cxt.getPtPosition());   
    addPoint(cxt.getNID(), new PVector(cxt.getPtPosition().getX(), cxt.getPtPosition().getY(), cxt.getPtPosition().getZ()));
  }

  public void OnPointDestroy(long nID)
  {
    println("OnPointDestroy, handId: " + nID);

    // remove list
    if (_pointLists.containsKey(nID))
      _pointLists.remove(nID);
  }

  public ArrayList getPointList(long handId)
  {
    ArrayList curList;
    if (_pointLists.containsKey(handId))
      curList = (ArrayList)_pointLists.get(handId);
    else
    {
      curList = new ArrayList(_maxPoints);
      _pointLists.put(handId, curList);
    }
    return curList;
  }
  public HashMap getPointLists()
  {
    return  _pointLists;
  }

  public void addPoint(long handId, PVector handPoint)
  {
    ArrayList curList = getPointList(handId);

    curList.add(0, handPoint);      
    if (curList.size() >  _maxPoints)
      curList.remove(curList.size() - 1);
  }

  public void draw()
  {
    if (_pointLists.size() <= 0)
      return;

    pushStyle();
    noFill();

    PVector vec;
    PVector firstVec;

    PVector screenPos = new PVector();
    int colorIndex=0;

    // draw the hand lists
    Iterator<Map.Entry> itrList = _pointLists.entrySet().iterator();
    while (itrList.hasNext ()) 
    {
      strokeWeight(2);
      stroke(_colorList[colorIndex % (_colorList.length - 1)]);

      ArrayList curList = (ArrayList)itrList.next().getValue();     

      // draw line
      firstVec = null;
      Iterator<PVector> itr = curList.iterator();
      beginShape();
      while (itr.hasNext ()) 
      {
        vec = itr.next();
        if (firstVec == null)
          firstVec = vec;
        // calc the screen pos
        context.convertRealWorldToProjective(vec, screenPos);
        vertex(screenPos.x, screenPos.y);
      }
      endShape();  



      // draw current pos of the hand
      if (firstVec != null)
      {
        strokeWeight(8);
        context.convertRealWorldToProjective(firstVec, screenPos);
        point(screenPos.x, screenPos.y);

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
          for (int x = 0; x <  3; x++) {
            for (int i = 0; i <  particles.size(); i++) {
              Particle particle = (Particle) particles.get(i);
              particle.solveConstraints();
            }
          }
        }

        // update each particle's position
        for (int i = 0; i <  particles.size(); i++) {
          Particle particle = (Particle) particles.get(i);
          particle.updatePhysics(fixedDeltaTimeSeconds); // the physics works in seconds, so fixedDeltaTime is divided by 1000
        }
        // we use a separate loop for drawing so points and their links don't get drawn more than once
        // (rendering can be a major resource hog if not done efficiently)
        // also, interactions (mouse dragging) is applied
        for (int i = 0; i <  particles.size(); i++) {
          Particle particle = (Particle) particles.get(i);
          particle.updateInteractions(screenPos);
          particle.draw();
        }
      }
      colorIndex++;
    }

    popStyle();
  }
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "OpenProcessingSketch" });
  }
}
