import controlP5.*;
import java.io.*;
import java.net.*;
import java.util.*;
import static javax.swing.JOptionPane.*;

ControlP5 cp5;

PImage login_image,start_image,game_image,wait_image;
PFont f;
boolean OK = true;
boolean loading = false;
boolean connectFailure = false;
boolean create_accountFailure = false;
boolean loginFailure = false;
boolean close_accountFailure = false;
//boolean waiting = false;

//variavel que informa que acabou o jogo
boolean game_over = false;

String textValue = "";
Textfield myTextfield;
int space;

//WINDOWS
final int start_window = 0;
final int login_window = 1;
final int wait_window = 2;
final int game_window = 3;
final int ranking_window = 4;
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
  wait_image = loadImage("espera.png");
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
        // state = game_window;
         state = wait_window;
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
    case wait_window:
      showWait();
      break;
    case game_window:
      showGame();
      break;
    case ranking_window:
      showRanking();
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

void showWait(){
  image(wait_image, 0, 0, width, height);
  cp5.getController("LOGIN").hide();
  cp5.getController("CLOSE ACCOUNT").hide();
  cp5.getController("CREATE AVATAR").hide();
  cp5.getController("USERNAME").hide();
  cp5.getController("PASSWORD").hide();
  cp5.getController("START").hide();

if(st.game_window)
  state = game_window;
  
String[] topPlayers = st.RankingScoreTOP();
String[] name = new String[topPlayers.length];
String[] score = new String[topPlayers.length];
for(int i=0; i<topPlayers.length;i++){
  if(topPlayers[i]==null) break;
  String[] splitSpace = topPlayers[i].trim().split("\\s+"); //"name score"
  name[i] = splitSpace[0];
  score[i] = splitSpace[1];
}

String[] topLevels = st.RankingLevelTOP();
String[] nameL = new String[topLevels.length];
String[] level = new String[topLevels.length];
for(int i=0; i<topLevels.length;i++){
  if(topLevels[i]==null) break;
  String[] splitSpace = topLevels[i].trim().split("\\s+"); //"name score"
  nameL[i] = splitSpace[0];
  level[i] = splitSpace[1];
}
textSize(30);
String s = new String();
String sl = new String();

fill(0,0,255);
if(!(name[0]==null)){
  s = Double.parseDouble(score[0]) == 0.0 ? "" : name[0];
  text(" "+s,100,325);
}
if(!(name[1]==null)){
  s = Double.parseDouble(score[1]) == 0.0 ? "" : name[1];
  text(" "+s,100,426);
}
if(!(name[2]==null)){
  s = Double.parseDouble(score[2]) == 0.0 ? "" : name[2];
  text(" "+s,100,520);
}

//Levels
if(!(nameL[0]==null)){
  sl = Integer.parseInt(level[0]) == 1 ? "" : nameL[0];
  text(" "+sl,585,325);
}

if(!(nameL[1]==null)){
  sl = Integer.parseInt(level[1]) == 1 ? "" : nameL[1];
  text(" "+sl,585,426);
}

if(!(nameL[2]==null)){
  sl = Integer.parseInt(level[2]) == 1 ? "" : nameL[2];
  text(" "+sl,585,520);
}

fill(153,0,51);
if(!(score[0]==null)){
  s = Double.parseDouble(score[0]) == 0.0 ? "" : score[0];
  text(" "+s,316,325);
}
if(!(score[1]==null)){
  s = Double.parseDouble(score[1]) == 0.0 ? "" : score[1];
  text(" "+s,316,426);
}
if(!(score[2]==null)){
  s = Double.parseDouble(score[2]) == 0.0 ? "" : score[2];
  text(" "+s,316,520);
}
if(!(level[0]==null)){
  sl = Integer.parseInt(level[0]) == 1 ? "" : level[0];
  text(" "+sl,800,325);
}

if(!(level[1]==null)){
  sl = Integer.parseInt(level[1]) == 1 ? "" : level[1];
  text(" "+sl,800,426);
}

if(!(level[2]==null)){
  sl = Integer.parseInt(level[2]) == 1 ? "" : level[2];
  text(" "+sl,800,520);
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
    ellipse(0,0,(float)elem[i][3],(float)elem[i][2]);
    triangle(0,((float)elem[i][3])/2,0,-((float)elem[i][3])/2,0.7*((float)elem[i][2]),0);
    }
    if(i==1){
    fill(playerTwo);
    ellipse(0,0,(float)elem[i][3],(float)elem[i][2]);
    triangle(0,((float)elem[i][3])/2,0,-((float)elem[1][3])/2,0.7*((float)elem[i][2]),0);
    }
    popMatrix();
    
    color(0,0,0);
    if(!(names[i]==null)){
      String PlayerName = "Nickname: ";
      String FrontEnergy = "Front Energy: ";
      String LeftEnergy = "Left Energy: ";
      String RightEnergy = "Right Energy: ";
      if(i==1){
        textSize(25);
        text(PlayerName,908-textWidth(PlayerName),space);
        text(FrontEnergy,944-textWidth(FrontEnergy),space+25);
        text(RightEnergy,944-textWidth(RightEnergy),space+50);
        text(LeftEnergy,925-textWidth(LeftEnergy),space+75);
        text(names[i],906,space);
        textSize(25);
        text(Double.toString(elem[1][5]),944,space+25);
        text(Double.toString(elem[1][7]),944,space+50);
        text(Double.toString(elem[1][6]),925,space+75);
        
      }
      space = 25;
      if(i==0){
        textSize(25);
        text(PlayerName,146-textWidth(PlayerName),space);
        text(FrontEnergy,180-textWidth(FrontEnergy),space+25);
        text(RightEnergy,180-textWidth(RightEnergy),space+50);
        text(LeftEnergy,161-textWidth(LeftEnergy),space+75);
        text(names[i],146,space);
        textSize(25);
        text(Double.toString(elem[0][5]),180,space+25);
        text(Double.toString(elem[0][7]),180,space+50);
        text(Double.toString(elem[0][6]),161,space+75);
        space = 25;
      }
    }
  }
 
 /*String[] ranking = st.RankingScoreTOP();
 text("Score:",width-textWidth("Score:")-60,height/2-180);
        for(int i = 0;i<ranking.length;i++,space +=20)
          text(ranking[i],width-textWidth(ranking[i]),height/2-180+space);*/
 //space = 25;
 
 //scores e reset do jogo
 if(st.game_over){
         st.game_window = false;
        double[][] score = st.playerPAtributes();
        showMessageDialog(null,"Game over!\nUsername: "+names[0]+" Score: "+score[0][0]+"\nUsername: "+names[1]+" Score: "+score[1][0], "Alert", ERROR_MESSAGE);
        st.game_over = false;
        st.ranking_window = true;
        st.clearGame(); //fica aqui?
        }
 if(st.ranking_window){
   state = ranking_window;
   st.ranking_window = false;
 }
}

void showRanking(){
  image(wait_image, 0, 0, width, height);
  cp5.getController("LOGIN").hide();
  cp5.getController("CLOSE ACCOUNT").hide();
  cp5.getController("CREATE AVATAR").hide();
  cp5.getController("USERNAME").hide();
  cp5.getController("PASSWORD").hide();
  cp5.getController("START").hide();


String[] topPlayers = st.RankingScoreTOP();
String[] name = new String[topPlayers.length];
String[] score = new String[topPlayers.length];
for(int i=0; i<topPlayers.length;i++){
  if(topPlayers[i]==null) break;
  String[] splitSpace = topPlayers[i].trim().split("\\s+"); //"name score"
  name[i] = splitSpace[0];
  score[i] = splitSpace[1];
}

String[] topLevels = st.RankingLevelTOP();
String[] nameL = new String[topLevels.length];
String[] level = new String[topLevels.length];
for(int i=0; i<topLevels.length;i++){
  if(topLevels[i]==null) break;
  String[] splitSpace = topLevels[i].trim().split("\\s+"); //"name score"
  nameL[i] = splitSpace[0];
  level[i] = splitSpace[1];
}
textSize(30);
String s = new String();
String sl = new String();

fill(0,0,255);
if(!(name[0]==null)){
  s = Double.parseDouble(score[0]) == 0.0 ? "" : name[0];
  text(" "+s,100,325);
}
if(!(name[1]==null)){
  s = Double.parseDouble(score[1]) == 0.0 ? "" : name[1];
  text(" "+s,100,426);
}
if(!(name[2]==null)){
  s = Double.parseDouble(score[2]) == 0.0 ? "" : name[2];
  text(" "+s,100,520);
}

//Levels
if(!(nameL[0]==null)){
  sl = Integer.parseInt(level[0]) == 0 ? "" : nameL[0];
  text(" "+sl,585,325);
}

if(!(nameL[1]==null)){
  sl = Integer.parseInt(level[1]) == 0 ? "" : nameL[1];
  text(" "+sl,585,426);
}

if(!(nameL[2]==null)){
  sl = Integer.parseInt(level[2]) == 0 ? "" : nameL[2];
  text(" "+sl,585,520);
}

fill(153,0,51);
if(!(score[0]==null)){
  s = Double.parseDouble(score[0]) == 0.0 ? "" : score[0];
  text(" "+s,316,325);
}
if(!(score[1]==null)){
  s = Double.parseDouble(score[1]) == 0.0 ? "" : score[1];
  text(" "+s,316,426);
}
if(!(score[2]==null)){
  s = Double.parseDouble(score[2]) == 0.0 ? "" : score[2];
  text(" "+s,316,520);
}
if(!(level[0]==null)){
  sl = Integer.parseInt(level[0]) == 0 ? "" : level[0];
  text(" "+sl,800,325);
}

if(!(level[1]==null)){
  sl = Integer.parseInt(level[1]) == 0 ? "" : level[1];
  text(" "+sl,800,426);
}

if(!(level[2]==null)){
  sl = Integer.parseInt(level[2]) == 0 ? "" : level[2];
  text(" "+sl,800,520);
}

text(" "+st.players_score_info,100,620);
text(" "+st.players_level_info,585,620);
}

void keyPressed() {
  //enviar("keyPress",Integer.toString(keyCode));
  System.out.println(" keycode: "+keyCode);
  if(state==game_window){
  if (keyCode == LEFT) {
    c.sendMessage("\\left");
  }
  if (keyCode == RIGHT) {
    c.sendMessage("\\right");
  }
  if (keyCode == UP) {
    c.sendMessage("\\front");
  }
  }
}