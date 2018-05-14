//import processing.core.PVector; 
import java.lang.*;

public class Avatar {
static double speed;
double dir; //angle
double x,y;
double h,w;
//boolean leftBoolean, rightBoolean, speedBoolean; 

Avatar(double speed, double dir, double x, double y, double h, double w) {
    this.speed = speed;
    this.dir = dir;
    this.x = x;
    this.y = y;  //ver depois como atualizar a posicao da nave através do erlang
    this.h = h;
    this.w = w;
  }
 
 public void updatePos(double x, double y){
   this.x = x;
   this.y = y;
 }
 
 public void updateDir(double dir){
   this.dir = dir;
 }

public double[] getAtributes(){
      double[] atrib = {x,y,h,w,dir};
      return atrib;
    }
   
public String toString(){
  return "Speed: " + speed + " Dir: " + dir + " X: " + x + " Y: " + y + " H: " + h + " W: " + w + "\n";
    }


/*
void DesenharAvatar() {
  x +=  Math.cos(dir)*(speed); // current location + the next "step"
  y +=  Math.sin(dir)*(speed);
  fill(65, 250, 255);
  pushMatrix();
  translate(x,y); 
  rotate(dir); 
   triangle(0, 0, -30, 20, -30, -20);
  // fill(255, 10, 50);
   rect(-38, 12  , 8, 8);
   rect(-38, 0, 8, 8);
   rect(-38, -12, 8, 8); 
  popMatrix();   

  if (leftBoolean == true) {
    dir -= .05;
  } 
  else if (rightBoolean == true) {
    dir += .05;
  } 
  if (speedBoolean == true) { 
    speed += .1;
  }
  else {
    speed -= .25;
  }
  speed = constrain(speed, 0, 4);
}


void keyPressed() {
  //enviar("keyPress",Integer.toString(keyCode));
  if (keyCode == LEFT) {
    leftBoolean = true;
  }
  if (keyCode == RIGHT) {
    rightBoolean = true;
  }
  if (keyCode == UP) {
    speedBoolean = true;
  }
}

void keyReleased() {
  //enviar("keyReleased",Integer.toString(keyCode));
  
  if (keyCode == LEFT) {
    leftBoolean = false;
  }
  if (keyCode == RIGHT) {
    rightBoolean = false;
  }
  if (keyCode == UP) {
    speedBoolean = false;
  }
 }
 */
}