class HardParticleDrower implements ParticleDrower {

  public HardParticleDrower() {
    println("HardParticleDrower initialization");
  };

  // The update function is used to update the physics of the particle.
  // motion is applied, and links are drawn here
  void updatePhysics (Particle particle, float timeStep) { // timeStep should be in elapsed seconds (deltaTime)
    // gravity:
    // f(gravity) = m * g
    PVector fg = new PVector(0, particle.mass * gravity);
    this.applyForce(particle, fg);

    /* Verlet Integration, WAS using http://archive.gamedev.net/reference/programming/features/verlet/ 
     however, we're using the tradition Velocity Verlet integration, because our timestep is now constant. */
    // velocity = position - lastPosition
    PVector velocity = PVector.sub(particle.position, particle.lastPosition);
    // apply damping: acceleration -= velocity * (damping/mass)
    particle.acceleration.sub(PVector.mult(velocity, particle.damping/particle.mass)); 
    // newPosition = position + velocity + 0.5 * acceleration * deltaTime * deltaTime
    PVector nextPos = PVector.add(PVector.add(particle.position, velocity), PVector.mult(PVector.mult(particle.acceleration, 0.1), timeStep * timeStep));
    // reset variables
    particle.lastPosition.set(particle.position);
    particle.position.set(nextPos);
   // particle.acceleration.set(0, 0, 0);


    // make sure the particle stays in its place if it's pinned
    if (particle.pinned)
      particle.position.set(particle.pinLocation);
  }

  void applyForce (Particle particle, PVector f) {
    // acceleration = (1/mass) * force
    // or
    // acceleration = force / mass
    particle.acceleration.add(PVector.div(PVector.mult(f, 1), particle.mass));
  }

  // here we tell each Link to solve constraints
  void solveConstraints (Particle particle) {
  }

  void updateInteractions (Particle particle) {
    // this is where our interaction comes in.
    int curX;
    int curY;
    int prevX;
    int prevY;
    //for (int idx = 0; idx < handPoints.size(); idx++) {
    if (handPoints.size() > 0) {  
      int idx = 0;
      curX = (int) handPoints.get(idx).getCurPos().x;
      curY = (int) handPoints.get(idx).getCurPos().y;
      if ( handPoints.get(idx).getPrevPos() != null) {
        prevX = (int) handPoints.get(idx).getPrevPos().x;
        prevY = (int) handPoints.get(idx).getPrevPos().y;
      }
      else {
        prevX = curX;
        prevY = curY;
      }

      
      float distanceSquared = sq(curX-width/2 - particle.position.x) + sq(curY-height/2 - particle.position.y);
      int xDiff = curX - prevX;
      int yDiff = curY - prevY;
      //     if (Math.abs(xDiff) > maxLenth) xDiff = sign(xDiff) * maxLenth;
      //     if (Math.abs(yDiff) > maxLenth) yDiff = sign(yDiff) * maxLenth;

      PVector addition = new PVector(0, yDiff/10);
      particle.position.add(addition);
    }
  }


  void draw (Particle particle) {
    // draw the links and points
    //stroke(255);
    if (particle.links.size() > 0) {
      for (int i = 0; i < particle.links.size(); i++) {
        Link currentLink = (Link) particle.links.get(i);
        if (currentLink.drawThis) // some links are invisible
          line(particle.position.x, particle.position.y, currentLink.p2.position.x, currentLink.p2.position.y);
      }      
    }
    point(particle.position.x, particle.position.y);
  }
}

