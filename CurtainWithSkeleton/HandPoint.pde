class HandPoint {
  private PVector curPos;
  private PVector prevPos;

  public HandPoint() {
  }

  public PVector getCurPos() {
    return curPos;
  }

  public PVector getPrevPos() {
    return prevPos;
  }

  public void nextPos(float newX, float newY, float newZ) {
    if (curPos == null){
      curPos = new PVector();
      prevPos = new PVector();
    }      
    prevPos.set(curPos);
    curPos.set(newX, newY, newZ);
  }
  
  public void nextPos(float newX, float newY) {
    if (curPos == null){
      curPos = new PVector();
      prevPos = new PVector();
    }      
    prevPos.set(curPos);
    curPos.set(newX, newY, 0);
  }  
}

