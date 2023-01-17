class Node{
  int x, y, z;
  boolean safe;
  ArrayList<Node> neighbors;
  int id;
  public Node(int tid, int tx, int ty, int tz, boolean tsafe){
    x = tx;
    y = ty;
    z = tz;
    id = tid;
    safe = tsafe;
    neighbors = new ArrayList<Node>(0);
  }
  void drawLines(PGraphics c){
    int[] coor = {x,y,z};
    for(int i = 0; i < neighbors.size(); i++){
      Node other = neighbors.get(i);
      int[] coor2 = {other.x,other.y,other.z};
      if(other.id > id){
        float thi = THICKNESS*DIST;
        color li = LINE_COLOR;
        if(PULSATE_LINES && frames >= 110 && frames < 510){
          li = pulsate(LINE_COLOR,color(255,0,0),(frames-110.0)/40);
        }
        if(PULSATE_NODES){
          if((x != y || other.x != other.y) && frames >= 48*60 && frames < 60*60){
            float fac = min(max(-3+4*abs(frames-54.0*60)/(6.0*60),0),1);
            thi *= fac;
          }
          if((!safe || !board.nodes[other.z][other.y][other.x].safe) && frames >= 101*60){
            float fac = 1-min(max((frames-101.0*60)/80,0),1);
            thi *= fac;
          }
        }
        if(frames >= 1000 && PULSATE_OPTIMAL_PATHS){
          int appX = round(min(pullData[z][y][x][0],pullData[other.z][other.y][other.x][0]));
          int appY = round(pullData[z][y][x][1]*2)+round(pullData[other.z][other.y][other.x][1]*2);
          int miniFrame = (frames-1000)/5;
          int maxiFrame = miniFrame/12;
          if(abs(appY) <= 1 && maxiFrame < 4){
            if(miniFrame%12 == appX){
              if((appY == 0) ||
              (appX <= 5 && maxiFrame%2 == 1-(appY+1)/2) ||
              (appX >= 5 && maxiFrame/2 == 1-(appY+1)/2)){
                li = color(255,0,0);
                thi *= 2;
              }
            }
          }
        }
        /*if(board.W >= 4){
          for(int p = 0; p < pathData.length-1; p++){
            boolean good = true;
            boolean good2 = true;
            for(int d = 0; d < 3; d++){
              if(coor[d] != pathData[p][d]
              || coor2[d] != pathData[p+1][d]){
                good = false;
              }
              if(coor[d] != pathData[p+1][d]
              || coor2[d] != pathData[p][d]){
                good2 = false;
              }
            }
            if(good || good2){
              li = color(255,40,0);
            }
          }
        }*/
        draw_3D_line(c,f(coor),f(coor2),thi,li);
      }
    }
  }
  void drawLinesFade(PGraphics c, int ex, int ey, float factor){
    int[] coor = {x,y,z};
    for(int i = 0; i < neighbors.size(); i++){
      Node other = neighbors.get(i);
      int[] coor2 = {other.x,other.y,other.z};
      float t = THICKNESS*DIST;
      if(other.x+ex >= 4 || other.y+ey >= 4){
        t *= factor;
      }
      if(other.id > id){
        draw_3D_line(c,f(coor),f(coor2),t,LINE_COLOR);
      }
    }
  }
  Node pickRandomNeighbor(){
    int index = (int)random(0,neighbors.size());
    return neighbors.get(index);
  }
  int getCoor(int d){
    int[] coor = {x,y,z};
    return coor[d];
  }
}
