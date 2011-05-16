class SlimyParticleDrower implements ParticleDrower {

  public SlimyParticleDrower() {
    println("SlimyParticleDrower initialization");
  };


  float mass = 10;
  float damping = 7000; // friction

  // The update function is used to update the physics of the particle.
  // motion is applied, and links are drawn here
  void updatePhysics (Particle particle, float timeStep) { // timeStep should be in elapsed seconds (deltaTime)
    // gravity:
    // f(gravity) = m * g
    PVector fg = new PVector(0, mass * gravity);
    this.applyForce(particle, fg);

    /* Verlet Integration, WAS using http://archive.gamedev.net/reference/programming/features/verlet/ 
     however, we're using the tradition Velocity Verlet integration, because our timestep is now constant. */
    // velocity = position - lastPosition
    PVector velocity = PVector.sub(particle.position, particle.lastPosition);
    // apply damping: acceleration -= velocity * (damping/mass)
    particle.acceleration.sub(PVector.mult(velocity, damping/mass)); 
    // newPosition = position + velocity + 0.5 * acceleration * deltaTime * deltaTime
    PVector nextPos = PVector.add(PVector.add(particle.position, velocity), PVector.mult(PVector.mult(particle.acceleration, 0.5), timeStep * timeStep));
    // reset variables
    particle.lastPosition.set(particle.position);
    particle.position.set(nextPos);
    particle.acceleration.set(0, 0, 0);


    // make sure the particle stays in its place if it's pinned
    if (particle.pinned)
      particle.position.set(particle.pinLocation);
  }

  void applyForce (Particle particle, PVector f) {
    // acceleration = (1/mass) * force
    // or
    // acceleration = force / mass
    particle.acceleration.add(PVector.div(PVector.mult(f, 1), mass));
  }

  // here we tell each Link to solve constraints
  void solveConstraints (Particle particle) {
    for (int i = 0; i < particle.links.size(); i++) {
      Link currentLink = (Link) particle.links.get(i);

      // calculate the distance between the two particles
      PVector delta = PVector.sub(currentLink.p1.position, currentLink.p2.position);
      float d = sqrt(delta.x * delta.x + delta.y * delta.y);

      float difference = 0;
      if (d !=0)
        difference = (currentLink.restingDistance - d) / d;

      currentLink.p1.position.add(PVector.mult(delta, currentLink.scalarP1 * difference));
      currentLink.p2.position.sub(PVector.mult(delta, currentLink.scalarP2 * difference));

      //Limit particle's motion with screen borders
      if (particle.position.y < -height/2+1)
        particle.position.y = -height/2+1;
      if (particle.position.y > height/2-1)
        particle.position.y = height/2-1;
      if (particle.position.x > width/2-1)
        particle.position.x = width/2-1;
      if (particle.position.x < -width/2+1)
        particle.position.x = -width/2+1;
    }
  }

  void updateInteractions (Particle particle) {
    // this is where our interaction comes in.
    int curX;
    int curY;
    int prevX;
    int prevY;
    for (int idx = 0; idx < handPoints.size(); idx++) {
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
      if (distanceSquared < mouseInfluenceSize) { // remember mouseInfluenceSize was squared in setup()

        // move particles towards where the mouse is moving
        // amount to add onto the particle position:
        int xDiff = curX - prevX;
        int yDiff = curY - prevY;
        PVector addition = new PVector(xDiff/3, yDiff/3);
        //addition.div(new PVector(3,3));
        particle.position.add(addition);
      }
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
      point(particle.position.x, particle.position.y);
    }
  }
}

