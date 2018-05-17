
import java.lang.*;

public class Player{
    private String username;
    private int score;
    
    Player(String user,int score){
      username = user;
      this.score = score;
    }
    
    public String getUsername(){
    return username;
    }
    
    public void setscore(int score){
      this.score = score;
    }
    
    public int getscore(){
      return score;
    }
    
    public String toString(){
      return "Player: " + username + " score: " + score +"\n";
    }
    
    /*public int compareTo(Player j){
      synchronized(j){
        if(score > j.getscore()) return -1;
        else if(score < j.getscore()) return 1;
        else return 0;
      }
    }
    */
    
}