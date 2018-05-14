
import java.net.*;
import java.io.*;
public class Client {
  private Socket sock = null;
  
  public void connect() throws ConnectException{
        try {
            sock = new Socket("localhost", 12345);
        } catch (ConnectException e) {
            throw e;
        } catch(Exception e){
            e.printStackTrace();
        }
    }

    public void disconnect() throws IOException{
         sock.close();
    }
    
    public void create_account(String user, String pass){
        try{
            PrintWriter out = new PrintWriter(sock.getOutputStream());
            out.println("\\create_account " + user + " " + pass);
            out.flush();
        }
         catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    public void login(String user, String pass){
      try{
        PrintWriter out = new PrintWriter(sock.getOutputStream());
        out.println("\\login " + user + " " + pass);
        out.flush();
      }
      catch (Exception e){
        e.printStackTrace();
      }
    }
     
      public void sendMessage(String message){
        try{
            PrintWriter out = new PrintWriter(sock.getOutputStream());
            out.println(message);
            out.flush();
        }catch (Exception e) {
            e.printStackTrace();
        }
    }
    
      public Socket getSocket() {
        return sock;
    }
}
        