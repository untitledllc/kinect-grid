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
  void updatePhysics (float timeStep) { // timeStep should be in elapsed seconds (deltaTime)
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
    PVector nextPos = PVector.add(PVector.add(position, velocity), PVector.mult(PVector.mult(acceleration, 0.5), timeStep * timeStep));
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

  void updateInteractions (PVector m) {

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

  void draw () {
    // draw the links and points
    stroke(0);
    if (links.size() > 0) {
      for (int i = 0; i < links.size(); i++) {
        Link currentLink = (Link) links.get(i);
        if (currentLink.drawThis) // some links are invisible
          line(position.x, position.y, currentLink.p2.position.x, currentLink.p2.position.y);
      }
    }
    else
      point(position.x, position.y);
  }
  // here we tell each Link to solve constraints
  void solveConstraints () {
    for (int i = 0; i < links.size(); i++) {
      Link currentLink = (Link) links.get(i);
      currentLink.constraintSolve();
    }
    // These if statements keep the particles within the screen
    if (position.y < -height/2+1)
      position.y = 2 * (-height/2 + 1) - position.y;
    if (position.y > height/2-1)
      position.y = 2 * (height/2 - 1) - position.y;
    if (position.x > width/2-1)
      position.x = 2 * (width/2 - 1) - position.x;
    if (position.x < -width/2+1)
      position.x = 2 * (-width/2 + 1) - position.x;
  }

  // attachTo can be used to create links between this particle and other particles
  void attachTo (Particle P, float restingDist, float stiff, boolean drawThis) {
    Link lnk = new Link(this, P, restingDist, stiff, drawThis);
    links.add(lnk);
  }
  void removeLink (Link lnk) {
    links.remove(lnk);
  }  

  void applyForce (PVector f) {
    // acceleration = (1/mass) * force
    // or
    // acceleration = force / mass
    acceleration.add(PVector.div(PVector.mult(f, 1), mass));
  }

  void pinTo (PVector location) {
    pinned = true;
    pinLocation.set(location);
  }
} 

