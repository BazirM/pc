import java.util.List;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.HashMap;
import java.util.Comparator;
import java.util.TreeSet;
import java.util.concurrent.locks.*;

public class Status{
    private Map<Player, Avatar> online;
    private Map<Integer,Monster> redmonsters;
    private Map<Integer,Monster> greenmonsters;
    private TreeSet<Player> rankingScore;
    private TreeSet<Level> rankingLevel;
    private Lock l = new ReentrantLock();
    boolean game_over = false;
    boolean game_window = false;
    //Informação acerca dos scores/levels dos jogadores da partida atual
    String players_level_info;
    String players_score_info;
    
    Status(){
      online = new LinkedHashMap<>();
      redmonsters = new HashMap<>();
      greenmonsters = new HashMap<>();
      game_over = false;
      game_window = false;
      rankingScore = new TreeSet();
      rankingLevel = new TreeSet();
      players_level_info = new String();
      players_score_info = new String();
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

    
    public void removeMonster(int i){
      l.lock();
      try{
        greenmonsters.remove(i);
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
      
      double[][] components = new double[2][8];
      int i = 0;
      try{
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          double[] atb = entry.getValue().getAtributes();
          components[i][0] = atb[0];
          components[i][1] = atb[1];
          components[i][2] = atb[2];
          components[i][3] = atb[3];
          components[i][4] = atb[4];
          components[i][5] = atb[5];
          components[i][6] = atb[6];
          components[i][7] = atb[7]; 
          i++;
        }
      }finally {
        l.unlock();
        return components;
      } 
    }
    
    public void updatePosition(String username,double x, double y, double energy){
      l.lock();
      try{
        Avatar a = null;
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          if(entry.getKey().getUsername().equals(username)){
            a = entry.getValue();
            a.updatePos(x,y);
            a.updateFrontEnergy(energy);
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
    
    
    public void updateDirection(String username,double dir,double energy, String e){
      l.lock();
      
      try{
        Avatar a = null;
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          if(entry.getKey().getUsername().equals(username)){
            a = entry.getValue();
            a.updateDir(dir);
            if(e.equals("l")){
              a.updateLeftEnergy(energy);
            } else if( e.equals("r")) {
                a.updateRightEnergy(energy);
              }
            break;
          }
            
          }
        
      }finally{
        l.unlock();
      }
    }
    
    public void chargeEnergy(String username, double le, double fe, double re){
      l.lock();
      try{
        Avatar a = null;
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          if(entry.getKey().getUsername().equals(username)){
            a = entry.getValue();
            a.updateFrontEnergy(fe);
            a.updateLeftEnergy(le);
            a.updateRightEnergy(re);
            break;
          }
        }
      }finally{
        l.unlock();
      }
    }
    
    public void updateScore(String username, double loserScore, double winnerScore){
      l.lock();
      try {
        Player p = null;
      for (Map.Entry<Player,Avatar> entry : online.entrySet()){
            if(entry.getKey().getUsername().equals(username)){
              p = entry.getKey();
              p.setScore(loserScore);
          }
          else {
            p = entry.getKey();
            p.setScore(winnerScore);
          }
        }
      }
      finally{l.unlock();
      }
    }
    
    public double[][] playerPAtributes(){
      l.lock();
      
      double[][] components = new double[2][1];
      int i = 0;
      try{
        for (Map.Entry<Player,Avatar> entry : online.entrySet()){
          double[] atb = entry.getKey().getAtributes();
          components[i][0] = atb[0];
          i++;
        }
      }finally {
        l.unlock();
        return components;
      } 
    }
    
    public void rankingScore(String username, int score){
      l.lock();
      try {
        rankingScore.add(new Player(username,score));
      }
      finally {
        l.unlock();
      }
    }
    
    public String[] RankingScoreTOP() {
      l.lock();
      int k = 0;
      String[] players = new String[3];
      try {
        for(Player p : rankingScore){
          if(k<3){
          players[k++] = p.toString();
          }
          else
          break;
        }
      }
      finally{
        l.unlock();
        return players;
      }
    }
    
    
    
    public void rankingLevel(String username, int level){
      l.lock();
      try {
        rankingLevel.add(new Level(username,level));
      }
      finally {
        l.unlock();
      }
    }
    
    public String[] RankingLevelTOP() {
      l.lock();
      int k = 0;
      String[] levels= new String[3];
      try {
        for(Level lp : rankingLevel){
          if(k<3){
          levels[k++] = lp.toString();
          }
          else
          break;
        }
      }
      finally{
        l.unlock();
        return levels;
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