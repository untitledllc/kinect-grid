class HandPoint {
  private PVector curPos;
  private PVector prevPos;

  public HandPoint() {
    // curPos = new PVector(x, y);
    // prevPos = new PVector(x, y);
  }

  public PVector getCurPos() {
    return curPos;
  }

  public PVector getPrevPos() {
    return prevPos;
  }
/*
  public void nextPos(PVector newPos) {
    prevPos = curPos;
    curPos = newPos;
  }
*/
  public void nextPos(int newX, int newY) {
    if (curPos == null){
      curPos = new PVector();
      prevPos = new PVector();
    }      
    prevPos.set(curPos);
    curPos.set(newX, newY, 0);
  }
}

