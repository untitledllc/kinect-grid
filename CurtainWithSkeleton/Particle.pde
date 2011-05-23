// the Particle class.
class Particle {
  PVector lastPosition; // for calculating position change (velocity)
  PVector position;

  PVector acceleration; 

  float mass = 10;
  float damping = 30; // friction

  // An ArrayList for links, so we can have as many links as we want to this particle :)
  ArrayList links = new ArrayList();

  boolean pinned = false;
  PVector pinLocation = new PVector(0, 0);


  // Particle constructor
  Particle (PVector pos) {
    position = pos.get();
    lastPosition = pos.get();
    acceleration = new PVector(0, 0, 0);   
  }

  // attachTo can be used to create links between this particle and other particles
  void attachTo (Particle P, float restingDist, float stiff, boolean drawThis) {
    Link lnk = new Link(this, P, restingDist, stiff, drawThis);
    links.add(lnk);
  }
  void removeLink (Link lnk) {
    links.remove(lnk);
  }  

  void pinTo (PVector location) {
    pinned = true;
    pinLocation.set(location);
  }
} 

