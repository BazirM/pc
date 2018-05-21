//import processing.core.PVector; 
import java.lang.*;

public class Avatar {

  static double speed;
  double dir; //angle
  double x,y;
  double h,w;
  double fe, le, re; //front energy ; left energy ; rigth energy


Avatar(double speed, double dir, double x, double y, double h, double w, double fe, double le, double re) {
    this.speed = speed;
    this.dir = dir;
    this.x = x;
    this.y = y;
    this.h = h;
    this.w = w;
    this.fe = fe;
    this.le = le;
    this.re = re;
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

public void updateLeftEnergy(double le){
	this.le = le;
}

public void updateRigthEnergy(double re){
	this.re = re;
}
public double[] getAtributes(){
      double[] atrib = {x,y,h,w,dir,fe,le,re};
      return atrib;
    }
   
public String toString(){
  return "Speed: " + speed + " Dir: " + dir + " X: " + x + " Y: " + y + " H: " + h + " W: " + w + "\n";
    }
}