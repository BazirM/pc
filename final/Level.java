
import java.lang.*;
public class Level implements Comparable<Level>{
    private String username;
    private int level;
    
    Level(String user,int level){
      username = user;
      this.level = level;
    }
    
    public String getUsername(){
    return username;
    }
    
    public void setLevel(int level){
      this.level = level;
    }
    
    public int getLevel(){
      return level;
    }
    
    public int[] getAtributes(){
      int[] l= {level};
      return l;
    }
    
    public String toString(){
      return " "+username+" "+level;
    }
    
    public int compareTo(Level l){
      synchronized(l){
        if(level > l.getLevel()) return -1;
        else if(level < l.getLevel()) return 1;
        else return username.compareTo(l.getUsername());
      }
    }
    
    
}