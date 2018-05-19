import controlP5.*;
import java.io.*;
import java.net.*;
import java.util.*;
import static javax.swing.JOptionPane.*;

ControlP5 cp5;

PImage login_image,start_image,game_image;
PFont f;
boolean OK = true;
boolean loading = false;
boolean connectFailure = false;
boolean create_accountFailure = false;
boolean loginFailure = false;
boolean close_accountFailure = false;

//variavel que informa que acabou o jogo
boolean game_over = false;

String textValue = "";
Textfield myTextfield;
int space;

//WINDOWS
final int start_window = 0;
final int login_window = 1;
//final int loading_window = 2;
final int game_window = 3;
int state = start_window;

//CLIENT, SOCKET, DATA
Client c = null;
Message m = null;
Status st = null;
String user,pass;
BufferedReader in = null;

//Avatar av = new Avatar(50,50,4);
float x,y,w,h;
 
void setup() {
  size(1024, 700, P3D);
  noStroke();
  PFont font = createFont("arial",15);
  cp5 = new ControlP5(this);
  
  login_image = loadImage("inicial.png");
  start_image = loadImage("inicial.png");
  game_image = loadImage("jogo.png");
  
  
  myTextfield = cp5.addTextfield("USERNAME")
     .setPosition(628,170) 
     .setSize(200,30)
     .setFont(createFont("arial",15))
     .setFocus(true)
     .setAutoClear(false)
     .setColor(color(255,255,255));
     
  myTextfield.setFocus(true);
  cp5.addTextfield("PASSWORD")
  .setPosition(628,225) 
     .setSize(200,30)
     .setFont(createFont("arial",15))
     .setFocus(true)
     .setColor(color(255,255,255))
     .setAutoClear(false)
     .setPasswordMode(true);
     
     cp5.addButton("START")
     .setValue(0)
     .setPosition(682,165) 
     .setSize(200,30)
     .setFont(font)
     .onPress(new CallbackListener() {  
       public void controlEvent(CallbackEvent theEvent){
        c = new Client();
          try {
            c.connect();
            in = new BufferedReader(new InputStreamReader(c.getSocket().getInputStream()));
            st = new Status();
            state = login_window;
          }
          catch(Exception e){
            connectFailure = true;
            state = start_window; 
          };
       }
     });
       
       
     cp5.addButton("LOGIN")
     .setValue(0)
     .setPosition(628,130) 
     .setSize(200,30)
     .setFont(font)
     .onPress(new CallbackListener() {  
       public void controlEvent(CallbackEvent theEvent){
      user = cp5.get(Textfield.class,"USERNAME").getText();
      pass = cp5.get(Textfield.class,"PASSWORD").getText();
      c.login(user,pass);
        try{
        String s = in.readLine();
        System.out.println("Login: "+s);
        if(s.equals("ok_login")){
          m = new Message(in,st);
          m.start();
          System.out.println("logged in!");
          cp5.hide();
          state = game_window;
        }
        else {
          loginFailure = true;
  state = login_window; // acrescentei
          }
        }
      catch(Exception e){
        state = login_window;
      }
      cp5.get(Textfield.class,"USERNAME").clear();
     cp5.get(Textfield.class,"PASSWORD").clear();
     }
   })
   ;
  
      cp5.addButton("CREATE AVATAR")
     .setValue(0)
     .setPosition(628,90) 
     .setSize(200,30)
     .setFont(font)
     .onPress(new CallbackListener() {  public void controlEvent(CallbackEvent theEvent) {
      //System.out.println("create account!");
      String user = cp5.get(Textfield.class,"USERNAME").getText();
      String pass = cp5.get(Textfield.class,"PASSWORD").getText();
      c.create_account(user,pass);
      try{
        String s = in.readLine();
        System.out.println("Create Avatar: "+s);
        if(s.equals("ok_create_account")){
         // m = new Message(in,st);
         // m.start();
          System.out.println("account created!");
          //cp5.hide();
          state = login_window;
        }
        else {
          create_accountFailure = true;
  state = login_window; // acrescentei
        }
      }
      catch(Exception e){
        state = login_window;
      }

     cp5.get(Textfield.class,"USERNAME").clear();
     cp5.get(Textfield.class,"PASSWORD").clear();
     }
   })
   ;

  cp5.addButton("CLOSE ACCOUNT")
     .setValue(0)
     .setPosition(628,50) 
     .setSize(200,30)
     .setFont(font)
     .onPress(new CallbackListener() {  public void controlEvent(CallbackEvent theEvent) {
      //System.out.println("close account!");
      String user = cp5.get(Textfield.class,"USERNAME").getText();
      String pass = cp5.get(Textfield.class,"PASSWORD").getText();
      c.close_account(user,pass);
      try{
        String s = in.readLine();
        System.out.println("Close Account: "+s);
        if(s.equals("ok_close_account")){
          System.out.println("account closed!");
          state = login_window;
        }
        else {
          close_accountFailure = true;
          state = login_window; // acrescentei
        }
      }
      catch(Exception e){
        state = login_window;
      }

     cp5.get(Textfield.class,"USERNAME").clear();
     cp5.get(Textfield.class,"PASSWORD").clear();  
     }
   })
   ;
   
   f = createFont("Dotum-20.vlw", 20, true);
   smooth();
}


void draw() {
  background(0);
  //PFont font = createFont("arial",10);
  switch(state){
    case start_window:
      showStart();
      break;
    case login_window:
      showLogin();
      break;
    case game_window:
      showGame();
      if(st.game_over){
        showMessageDialog(null,"Game over!", "Alert", ERROR_MESSAGE);
        st.game_over = false;
      }
      break;
  }
}

void showStart(){
  image(start_image,0,0,width,height);
  cp5.getController("LOGIN").hide();
  cp5.getController("CLOSE ACCOUNT").hide();
  cp5.getController("CREATE AVATAR").hide();
  cp5.getController("USERNAME").hide();
  cp5.getController("PASSWORD").hide();
  cp5.getController("START").show();
  
   if(connectFailure==true){
      showMessageDialog(null,"Connection failure!", "Alert", ERROR_MESSAGE);
      connectFailure = false;
  }
}

void showLogin() {
  image(login_image, 0, 0, width, height);
  cp5.getController("LOGIN").show();
  cp5.getController("CLOSE ACCOUNT").show();
  cp5.getController("CREATE AVATAR").show();
  cp5.getController("USERNAME").show();
  cp5.getController("PASSWORD").show();
  cp5.getController("START").hide();
  
  if(loginFailure == true){
    showMessageDialog(null,"Failed to log in!", "Alert", ERROR_MESSAGE);
    loginFailure = false;
    }
    
    if(create_accountFailure == true){
      showMessageDialog(null,"This account already exists!", "Alert", ERROR_MESSAGE);
      create_accountFailure = false;
    }

   if(close_accountFailure == true){
  showMessageDialog(null,"This account does not exist!", "Alert", ERROR_MESSAGE);
  close_accountFailure = false;
   }
}

void showGame(){
  image(game_image, 0, 0, width, height);
  cp5.getController("LOGIN").hide();
  cp5.getController("CLOSE ACCOUNT").hide();
  cp5.getController("CREATE AVATAR").hide();
  cp5.getController("USERNAME").hide();
  cp5.getController("PASSWORD").hide();
  cp5.getController("START").hide();
  
  //background(255, 255, 255);
  String[] names = st.getNames();
  double[][] elem = st.playerAtributes();
  double[][] redmonst = st.redMonsterAtributes();
  double[][] greenmonst = st.greenMonsterAtributes();
  
  
  color monsterRed = color(204, 0, 0);
  color monsterGreen = color(102, 153, 0);
  color playerOne = color(255, 133, 51);
  color playerTwo = color(102, 179, 255);
  
  pushMatrix();
  for(int i = 0; i<redmonst.length; i++){
       fill(monsterRed);
       x = (float) redmonst[i][0];
       y = (float) redmonst[i][1];
       h = (float) redmonst[i][2];
       w = (float) redmonst[i][3];
       ellipse(x,y,h,w);
     }
  popMatrix();
  pushMatrix();
  for(int i = 0; i<greenmonst.length; i++){
       fill(monsterGreen);
       x = (float) greenmonst[i][0];
       y = (float) greenmonst[i][1];
       h = (float) greenmonst[i][2];
       w = (float) greenmonst[i][3];
       //System.out.println(" monstro " + " i " + " -> " + "x : " + x + " y : " + y + " h: " + h + " w " + w);
       ellipse(x,y,h,w);
     }
  popMatrix();
     
  for(int i=0; i<elem.length;i++){
    x= (float) elem[i][0];
    y= (float) elem[i][1];
    
    pushMatrix();
    translate(x,y);
    rotate(radians((float)elem[i][4])); //dir
    if(i==0){
    fill(playerOne);
    ellipse(0,0,(float)elem[0][3],(float)elem[0][2]);
    triangle(0,((float)elem[0][3])/2,0,-((float)elem[0][3])/2,0.7*((float)elem[0][2]),0);
    }
    if(i==1){
    fill(playerTwo);
    ellipse(0,0,(float)elem[1][3],(float)elem[1][2]);
    triangle(0,((float)elem[1][3])/2,0,-((float)elem[1][3])/2,0.7*((float)elem[1][2]),0);
    }
    popMatrix();
    
    color(0,0,0);
    if(!(names[i]==null)){
      String PlayerName = "Nickname:";
      String FrontEnergy = "Front Energy:";
      if(i==0){
        text(PlayerName,50-textWidth(PlayerName),space);
        text(FrontEnergy,50-textWidth(FrontEnergy),space+20);
        
        text(names[i],50,space);
        space+=20;
        text(Double.toString(elem[0][5]),50,space);
        space = 20;
      }
  }
 }
}

void keyPressed() {
  //enviar("keyPress",Integer.toString(keyCode));
  System.out.println(" keycode: "+keyCode);
  if(state==game_window){
  if (keyCode == LEFT) {
    //av.leftBoolean = true;
    System.out.println("Keypressed: left");
    c.sendMessage("\\left");
    
  }
  if (keyCode == RIGHT) {
    //av.rightBoolean = true;
    c.sendMessage("\\right");
  }
  if (keyCode == UP) {
    //av.speedBoolean = true;
    c.sendMessage("\\front");
  }
  }
}

//Movimento contínuo
/*void keyReleased() {
  //enviar("keyReleased",Integer.toString(keyCode));
  if(state==game_window){
  if (keyCode == LEFT) {
    av.leftBoolean = false;
  }
  if (keyCode == RIGHT) {
    av.rightBoolean = false;
  }
  if (keyCode == UP) {
    av.speedBoolean = false;
  }
 }
}*/
  
  
/*void showLoading() {
  image(login_image, 0, 0, width, height);
  if(OK == true)
  {
    loading = true;
    frameCount = 1;
    OK = false;
  }
  if(loading == false)
  {
    fill(255);
    textAlign(CENTER);
    //text (tx, 150, 150);
  }
  if(loading == true)
  {
    fill(255);
    textAlign(LEFT);
    text ("LOADING " + int((frameCount%301) / 3) + "%", 50, 130);
    rect(48, 138, 204, 24);
    fill(0);
    int fillX = ((frameCount%301) / 3 * 2);
    rect(250, 140, fillX-200, 20);
    if(frameCount%301 == 0)
    {
      System.out.println("Ok");
      loading = false;
    }
  }
}*/