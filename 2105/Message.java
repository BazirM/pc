import java.io.*;
import java.util.*;

public class Message extends Thread {
  Status st;
  private BufferedReader in;
  
   Message(BufferedReader in, Status st){
        this.in = in;
        this.st = st;
    }
    
    public void run(){
        try {
            while(true){
              String s = in.readLine();
              System.out.println(s);
              String[] token = s.split(" ");
              
              
             if(token[0].equals("online")){
                Player p = new Player(token[1],Integer.parseInt(token[2]));
                Avatar a = new Avatar(Double.parseDouble(token[3]), Double.parseDouble(token[4]),
                Double.parseDouble(token[5]),Double.parseDouble(token[6]),
                Double.parseDouble(token[7]),Double.parseDouble(token[8]),Double.parseDouble(token[9]),Double.parseDouble(token[10]),Double.parseDouble(token[11]));
                st.addPlayer(p,a);
               }
            
            if(token[0].equals("add_green_monster")){
              int i = Integer.parseInt(token[1]);
              Monster m = new Monster(Double.parseDouble(token[2]),Double.parseDouble(token[3]),Double.parseDouble(token[4]),Double.parseDouble(token[5]),
                          Double.parseDouble(token[6]),Integer.parseInt(token[7]));
              st.addMonster(i,m);
            }
            
            if(token[0].equals("remove_green_monster")){
              int i = Integer.parseInt(token[1]);
              st.removeMonster(i);
            }
            
            if(token[0].equals("add_red_monster")){
              int i = Integer.parseInt(token[1]);
              Monster m = new Monster(Double.parseDouble(token[2]),Double.parseDouble(token[3]),Double.parseDouble(token[4]),Double.parseDouble(token[5]),
                          Double.parseDouble(token[6]),Integer.parseInt(token[7]));
              st.addMonster(i,m);
            }
            
            if(token[0].equals("green_monster_upt")){
              int i = Integer.parseInt(token[1]);
              System.out.println("Valor de i: "+i);
              st.updatePositionMonster(i,Double.parseDouble(token[2]),Double.parseDouble(token[3]),Integer.parseInt(token[4]));
            }
            
            if(token[0].equals("red_monster_upt")){
              int i = Integer.parseInt(token[1]);
              System.out.println("Valor de i: "+i);
              st.updatePositionMonster(i,Double.parseDouble(token[2]),Double.parseDouble(token[3]),Integer.parseInt(token[4]));
            }
            
            if(token[0].equals("on_update_left")){
              //Username, Le
              st.updateDirection(token[1],Double.parseDouble(token[2]),Double.parseDouble(token[3]),"l");
            }
            
            if(token[0].equals("on_update_right")){
              //Username, Re
              st.updateDirection(token[1],Double.parseDouble(token[2]),Double.parseDouble(token[3]),"r");
            }
            
            if(token[0].equals("on_update_front")){
              //Username, X, Y, Fe
              st.updatePosition(token[1],Double.parseDouble(token[2]),Double.parseDouble(token[3]),Double.parseDouble(token[4]));
            }
            
            if(token[0].equals("game_over")) {
                st.game_over = true;
                st.clearGame();
                //state = login_window;
               }
               
               //left front right
             if(token[0].equals("charge")){
               //Username, left front right
               st.chargeEnergy(token[1],Double.parseDouble(token[2]),Double.parseDouble(token[3]),Double.parseDouble(token[4]));
             }
            }
        }
        catch(Exception e){
          e.printStackTrace();
        }
    }
}