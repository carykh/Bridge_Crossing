class Board{
  int W;
  int L;
  int H;
  Node[][][] nodes;
  public Board(int w, int l, int h, boolean ban){
    W = w;
    L = l;
    H = h;
    nodes = new Node[H+1][L+1][W+1];
    int id = 0;
    for(int z = 0; z <= H; z++){
      for(int y = 0; y <= L; y++){
        for(int x = 0; x <= W; x++){
          nodes[z][y][x] = new Node(id,x,y,z,(x == 0 || x == W || x == y));
          id++;
        }
      }
    }
    int[][] travelTypes = {{1,1,1},{1,0,1},{2,0,1},{0,1,1},{0,2,1}};
    //int[][] travelTypes = {{0,0,1},{0,1,0},{1,0,0}};
    for(int z = 0; z <= H; z++){
      for(int y = 0; y <= L; y++){
        for(int x = 0; x <= W; x++){
          for(int i = 0; i < travelTypes.length; i++){
            int dx = travelTypes[i][0];
            int dy = travelTypes[i][1];
            int dz = travelTypes[i][2];
            int[] coor = {x,y,z};
            int[] coor2 = {x+dx,y+dy,z+dz};
            if(allowed(coor,coor2,ban)){
              Node me = nodes[z][y][x];
              Node them = nodes[z+dz][y+dy][x+dx];
              me.neighbors.add(them);
              them.neighbors.add(me);
            }
          }
        }
      }
    }
  }
  Node getNode(int c[]){
    return nodes[c[2]][c[1]][c[0]];
  }
  boolean getSafe(int x, int y, int z){
    if(!BAN_DANGEROUS){
      return true;
    }
    return nodes[z][y][x].safe;
  }
  boolean getSafe(int c[]){
    return getSafe(c[0],c[1],c[2]);
  }
  boolean getEnding(int[] c){
    boolean isStart = true;
    boolean isEnd = true;
    for(int d = 0; d < 3; d++){
      if(c[d] != 0){
        isStart = false;
      }
      if(c[d] != getDimSize(d)){
        isEnd = false;
      }
    }
    return (isStart || isEnd);
  }
  color getDimColor(int d){
    color[] colors = {color(128,0,0), color(0,110,0), color(0,0,200)};
    return colors[d];
  }
  int getDimSize(int d){
    int[] dims = {W,L,H};
    return dims[d];
  }
  String getDimLabel(int d){
    String[] labels = {"Santas","Dinosaurs","Rafts"};
    return labels[d];
  }
  boolean allowed(int[] coor1, int[] coor2, boolean ban){
    return (allowed(coor1, ban) && allowed(coor2, ban));
  }
  boolean allowed(int[] coor, boolean ban){
    for(int d = 0; d < 3; d++){
      if(coor[d] < 0 || coor[d] > getDimSize(d)){
        return false;
      }
    }
    if(ban && !getSafe(coor)){
      return false;
    }
    return true;
  }
}
