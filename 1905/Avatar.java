//import processing.core.PVector; 
import java.lang.*;

public class Avatar {

  static double speed;
  double dir; //angle
  double x,y;
  double h,w;
  double fe; //front energy


Avatar(double speed, double dir, double x, double y, double h, double w, double fe) {
    this.speed = speed;
    this.dir = dir;
    this.x = x;
    this.y = y;
    this.h = h;
    this.w = w;
    this.fe = fe;
  }
 
 public void updatePos(double x, double y){
   this.x = x;
   this.y = y;
 }
 
 public void updateDir(double dir){
   this.dir = dir;
 }
 
 public void updateFrontEnergy(double fe){
   this.fe = fe;
 }

public double[] getAtributes(){
      double[] atrib = {x,y,h,w,dir,fe};
      return atrib;
    }
   
public String toString(){
  return "Speed: " + speed + " Dir: " + dir + " X: " + x + " Y: " + y + " H: " + h + " W: " + w + "\n";
    }
}