/* 
 Curtain (Fabric Simulator)
 Made by BlueThen on February 5th, 2011; updated February 10th and 11th, 2011
 To interact, left click and drag, right click to tear, 
 press 'G' to toggle gravity, and press 'R' to reset
 www.bluethen.com
 */

import SimpleOpenNI.*;
import fullscreen.*; 



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
float gravity = 0; 

// Dimensions for our curtain. These are number of particles for each direction, not actual widths and heights
// the true width and height can be calculated by multiplying restingDistances by the curtain dimensions
final int k=3;
final int curtainHeight = 14*k;
final int curtainWidth = 24*k;
final int yStart = 50; // where will the curtain start on the y axis?
final float restingDistances = 30/k;
final float stiffnesses = 1;
final int curtainTearSensitivity = 100; // distance the particles have to go before ripping
final boolean showHandsPaths = true;
final int scrWidth = 800;
final int scrHeight = 600;

// Create the fullscreen object
FullScreen fs;



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
int leftOverDeltaTime = 1;

// instructional stuffs:
PFont font;
final int instructionLength = 3000;
final int instructionFade = 300;
void setup () {
    
    
    // enter fullscreen mode
    fs = new FullScreen(this); 
    //fs.enter();
    
  // Processing's default renderer is Java2D
  // but we instead use P2D, because it is a lot faster (about 2-3 times faster for me)
  size(scrWidth, scrHeight,P2D);

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
  //context.setSmoothingHands(.5);
  // setup NITE 
  sessionManager = context.createSessionManager("Click,Wave", "RaiseHand");



  pointDrawer = new PointDrawer();
  flowRouter = new XnVFlowRouter();
  flowRouter.SetActive(pointDrawer);

  //sessionManager.AddListener(flowRouter);

  //size(context.depthWidth(), context.depthHeight()); 
  smooth();
}

void draw () {

  background(0, 0, 0);
  // update the cam
  context.update();

  // update nite
  context.update(sessionManager);

  // draw depthImageMap
  image(context.depthImage(), 0, 0, 0,0); //scrWidth, scrHeight
  //context.depthImage();

  // draw the list
  pointDrawer.draw();

  //background(255);
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
         particle.solveConstraints();
       }
     }
   }

   // update each particle's position
   for (int i = 0; i < particles.size(); i++) {
     Particle particle = (Particle) particles.get(i);
     particle.updatePhysics(fixedDeltaTimeSeconds); // the physics works in seconds, so fixedDeltaTime is divided by 1000
   }
   // we use a separate loop for drawing so points and their links don't get drawn more than once
   // (rendering can be a major resource hog if not done efficiently)
   // also, interactions (mouse dragging) is applied
   for (int i = 0; i < particles.size(); i++) {
     Particle particle = (Particle) particles.get(i);
     particle.updateInteractions(); //pointDrawer.getMultiPositions()
     if (particle.getLinksCount() == 0) 
       {}// particles.remove(i); 
     else
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
  // enter fullscreen mode
  if ((key == 'f') || (key == 'F'))
    toggleFullScreen();
  switch(key)
  {
  case 'e':
    // end sessions
    sessionManager.EndSession();
    println("end session");
    break;
  }
}

void toggleFullScreen () {
  if (fs.isFullScreen()){
 //     final int scrWidth = 640;
   //   final int scrHeight = 480;
      size(scrWidth, scrHeight);
      fs.leave();
  }
    
  else{
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

void drawInstructions () {
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

void onStartSession(PVector pos)
{
  println("onStartSession: " + pos);
}

void onEndSession()
{
  println("onEndSession: ");
}

void onFocusSession(String strFocus, PVector pos, float progress)
{
  println("onFocusSession: focus=" + strFocus + ",pos=" + pos + ",progress=" + progress);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// PointDrawer keeps track of the handpoints

class PointDrawer extends XnVPointControl
{
  HashMap    _pointLists;
  int        _maxPoints;
  color[]    _colorList = { 
    color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0)
  };
  
  private ArrayList<PVector> multiPositions = new ArrayList<PVector>();
  
  public ArrayList<PVector> getMultiPositions()
  {
      return multiPositions;
  }
  

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
    if (curList.size() > _maxPoints)
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
    
    //multiPositions.clear();

    // draw the hand lists
    Iterator<Map.Entry> itrList = _pointLists.entrySet().iterator();
    while (itrList.hasNext ()) 
    {
      strokeWeight(2);
      stroke(_colorList[colorIndex % (_colorList.length - 1)]);

      ArrayList curList = (ArrayList)itrList.next().getValue();     
      
      
	  
        
        // draw line        
        Iterator<PVector> itr = curList.iterator();
        firstVec = null;
        beginShape();
          while (itr.hasNext()) 
          {
            vec = itr.next();
            if(firstVec == null)
              firstVec = vec;
            // calc the screen pos
            
            context.convertRealWorldToProjective(vec,screenPos);
            if (showHandsPaths) {
                vertex(screenPos.x,screenPos.y);
            }
          } 
        endShape();   
	  
	
	
        // draw current pos of the hand
        if(firstVec != null)
        {
         	
          	context.convertRealWorldToProjective(firstVec,screenPos);
          	
            if (showHandsPaths) {	
                strokeWeight(8);
          	    point(screenPos.x,screenPos.y);
		    }
	        mouseX = (int) screenPos.x;		
		    mouseY = (int) screenPos.y;  
		    println("X, Y: " + mouseX + ", " + mouseY);
		    //multiPositions.add(screenPos); 
        }
        
        colorIndex++;
      }
    popStyle();
  }
}

