
import java.lang.*;

public class Player{
    private String username;
    private double score;
    
    Player(String user,double score){
      username = user;
      this.score = score;
    }
    
    public String getUsername(){
    return username;
    }
    
    public void setScore(double score){
      this.score = score;
    }
    
    public double getScore(){
      return score;
    }
    
    public double[] getAtributes(){
      double[] p= {score};
      return p;
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