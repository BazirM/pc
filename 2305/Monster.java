
public class Monster {
    private double x,y;
    private double h,w;
    private double speed;
    int type;
    //0 = red
    //1 = green
    
    Monster(double speed, double x, double y, double h, double w, int type){
      this.speed = speed;
      this.x = x;
      this.y = y;
      this.type=type;
      this.h = h;
      this.w = w;
    }
    
    public double[] getAtributes(){
      double[] f = {x,y,h,w,type};
      return f;
    }
    
    public void updatePos(double x, double y){
      this.x = x;
      this.y = y;
    }
}