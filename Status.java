import java.util.List;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.locks.*;

public class Status{
    private Map<Player, Avatar> online;
    private Map<Integer,Monster> redmonsters;
    private Map<Integer,Monster> greenmonsters;
    private Lock l = new ReentrantLock();
    
    Status(){
      online = new LinkedHashMap<>();
      redmonsters = new HashMap<>();
      greenmonsters = new HashMap<>();
    }
    
    public void addMonster(int i, Monster m){
      l.lock();
      
      try{
        if(m.type==0)
            redmonsters.put(i,m);
        else if (m.type==1)
            greenmonsters.put(i,m);
      }
      finally{
        l.unlock();
      } 
    }
    
    public void addPlayer(Player p, Avatar a){
      l.lock();
      try{
        online.put(p,a);  
      }
      finally{
        l.unlock();
      }
    }
    
    public String[] getNames(){
      l.lock(); 
      int i=0; 
      String[] names = new String[2];
        try{
         for(Map.Entry<Player,Avatar> entry : online.entrySet()){
             names[i] = entry.getKey().getUsername();
             i++;
         }
        }finally{
          l.unlock();
          return names;
        } 
    }
    
    public double[][] redMonsterAtributes(){
      l.lock();
      int N = redmonsters.size();
      double[][] redmonst = new double[N][5];
      try{
      int i = 0;
      for (Map.Entry<Integer,Monster> entry : redmonsters.entrySet()){
        double[] atb = entry.getValue().getAtributes();
        redmonst[i][0] = atb[0];
        redmonst[i][1] = atb[1];
        redmonst[i][2] = atb[2];
        redmonst[i][3] = atb[3];
        redmonst[i][4] = atb[4];
        i++;
      }
     }
      finally{
        l.unlock();
        return redmonst;
      }
    }
    
    public double[][] greenMonsterAtributes(){
      l.lock();
      int N = greenmonsters.size();
      double[][] greenmonst = new double[N][5];
      try{
      int i = 0;
      for (Map.Entry<Integer,Monster> entry : greenmonsters.entrySet()){
        double[] atb = entry.getValue().getAtributes();
        greenmonst[i][0] = atb[0];
        greenmonst[i][1] = atb[1];
        greenmonst[i][2] = atb[2];
        greenmonst[i][3] = atb[3];
        greenmonst[i][4] = atb[4];
        i++;
      }
     }
      finally{
        l.unlock();
        return greenmonst;
      }
    }
    
    public double[][] playerAtributes(){
      l.lock();
      
      double[][] elements = new double[2][5];
      int i = 0;
      try{
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          double[] atb = entry.getValue().getAtributes();
          elements[i][0] = atb[0]; elements[i][1] = atb[1];
          elements[i][2] = atb[2]; elements[i][3] = atb[3];
          elements[i][4] = atb[4];
          i++;
        }
      }finally{
        l.unlock();
        return elements;
      } 
    }
    
    public void updatePosition(String username,double x, double y){
      l.lock();
      try{
        Avatar a = null;
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          if(entry.getKey().getUsername().equals(username)){
            a = entry.getValue();
            a.updatePos(x,y);
            break;
          }
        }
      }finally{
        l.unlock();
      }
    }
    
    public void updatePositionMonster(int i, double x, double y,int type){
      l.lock();
      try {
        Monster m = null;
        if(type==0){
        m = redmonsters.get(i);
        m.updatePos(x,y);
        }
        else if(type==1){
          m=greenmonsters.get(i);
          m.updatePos(x,y);
        }
      }
      finally{
        l.unlock();
      }  
    }
    
    public void updateDirection(String username,double dir){
      l.lock();
      
      try{
        Avatar a = null;
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          if(entry.getKey().getUsername().equals(username)){
            System.out.println("Username no map: "+entry.getKey().getUsername()+ "Username no argumento: "+username);
            a = entry.getValue();
            a.updateDir(dir);
            break;
          }
        }
      }finally{
        l.unlock();
      }
    }
    
    public String toString(){
      String s = "";
      for (Map.Entry<Player,Avatar> entry : online.entrySet()){
        s += entry.getKey().toString() + entry.getValue().toString();
      }
      return s;
    }
}