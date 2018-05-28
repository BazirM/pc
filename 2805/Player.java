
import java.lang.*;

public class Player implements Comparable<Player>{
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
      //return "Player: " + username + " score: " + score +"\n";
      return " "+username+" "+score;
    }
    
    public int compareTo(Player p){
      synchronized(p){
        if(score > p.getScore()) return -1;
        else if(score < p.getScore()) return 1;
        else return username.compareTo(p.getUsername());
      }
    }
    
    
}