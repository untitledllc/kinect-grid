class HardParticleDrower implements ParticleDrower {
  /*  
   private HardParticleDrower instance;
   
   private HardParticleDrower(){
   };
   
   //Singleton implementation
   public static synchronized HardParticleDrower getInstance(){
   if (instance == null){
   instance = new HardParticleDrower();
   }
   return instance;
   }
   */

  public HardParticleDrower() {
    println("HardParticleDrower initialization");
  };

  // The update function is used to update the physics of the particle.
  // motion is applied, and links are drawn here
  void updatePhysics (Particle particle, float timeStep) { // timeStep should be in elapsed seconds (deltaTime)
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

      PVector addition = new PVector(xDiff, yDiff);
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
      point(particle.position.x, particle.position.y);
    }
  }
}

