class RaggyParticleDrower extends DefaultParticleDrower {

  public RaggyParticleDrower() {
    println("RaggyParticleDrower initialization");
  };


  float mass = 10;
  float damping = 10; // friction
  final int curtainTearSensitivity = 100; // distance the particles have to go before ripping

  // here we tell each Link to solve constraints
  void solveConstraints (Particle particle) {
  
    for (int i = 0; i < particle.links.size(); i++) {
      Link currentLink = (Link) particle.links.get(i);

      // calculate the distance between the two particles
      PVector delta = PVector.sub(currentLink.p1.position, currentLink.p2.position);
      float d = sqrt(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z);

      float difference = 0;
      if (d !=0)
        difference = (currentLink.restingDistance - d) / d;

      if (d > curtainTearSensitivity) 
        currentLink.p1.removeLink(currentLink);  

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
      if (particle.position.z > width/5-1)
        particle.position.z = width/5-1;
      if (particle.position.z < -width/5+1)
        particle.position.z = -width/5+1;
        
    }
  }
}

