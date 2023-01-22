import com.hamoid.*;
VideoExport videoExport;

// Note: the size/location of sprites on the right-side animation (santas, dinos, rafts)
// doesn't scale well when increasing the number above the default 3,3,1.
// I changed them manually in the function "drawSide()", which is hard-to-reproduce, sorry about that.

String PATH_FILENAME = "path.tsv"; // input file describing the path the cursor will take
String PULL_FILENAME = "pull_data.tsv"; // input file describing where the nodes should go during a "pull-apart" animation
String VIDEO_FILE_NAME = "video_file.mp4"; // output file where the video will be outputted. You must pressed "ESC" while the video is rendering (don't click the stop button) for it to save.

boolean BAN_DANGEROUS = true;
boolean PULSATE_LINES = false;
boolean PULSATE_NODES = false;
boolean DO_PULL_ANIMATION = false;
boolean DRAW_HIGHLIGHT = true;
boolean DRAW_DANGEROUS = true;
boolean PULSATE_OPTIMAL_PATHS = false;
boolean DRAW_VERTICAL_GRIDLINES = true;
boolean LOCK_CAMERA = true;  // if false, it will track your mouse, but your mouse has to be on-screen
boolean SAVE_VIDEO = true;

int transitionLength = 100;
int blinkLength = 14;
int PLAY_SPEED = 1;



float DIST = 200; // How "scaled-up" should the graph be?
Board board = new Board(3, 3, 1, true);

color bg = color(150, 200, 255);
float PULL_DIST = 145; // only relevant if you're doing a pull-apart animation
float RAD = 0.11;//0.11;
float HIGHLIGHT_RAD = 0.12;//0.12;
float THICKNESS = 0.032; //0.033;
float GRID_THICKNESS = 0.02; //0.02;
color BALL_COLOR = color(255, 255, 0);
color DANGER_COLOR = color(190, 0, 30);
color LINE_COLOR = color(140, 140, 140);
color HIGHLIGHT_COLOR = color(0, 255, 0);
color END_COLOR = color(255, 100, 240);
color WHITE = color(255, 255, 255);
float W_W = 1280;
float W_H = 1080;
float S_W = 640;
float S_H = 1080;
float Z_SHIFT = -0.14;
float TURN_SPEED = 0.0005;
float STARTING_ANGLE = 0.06;
int zoom = 0;
int[][] location = new int[2][3];
int transitionTime = -1;
PFont font;
int frames = 0;
PImage[] sideImages;

PGraphics canvas;
PGraphics side;
float Xang, Yang;


String[] pathDataStr;
int[][] pathData;
int pathIndex = 0;

String[] pullDataStr;
float[][][][] pullData;
float pullFac;

int RANDOM_WALK = 0; // 0 = follow specified path, 1 = move randomly along pre-existing paths, 2 = go absolutely wherever randomly
void setup() {
  font = loadFont("Calibri-Bold-48.vlw");
  size(1920, 1080, P3D);
  canvas = createGraphics((int)W_W, (int)W_H, P3D);
  side = createGraphics((int)S_W, (int)S_H, P3D);

  processPathData();
  processPullData();

  sideImages = new PImage[3];
  for (int d = 0; d < 3; d++) {
    sideImages[d] = loadImage("p"+d+".png");
  }
  if(SAVE_VIDEO){
    videoExport = new VideoExport(this, VIDEO_FILE_NAME);
    videoExport.setFrameRate(60);
    videoExport.startMovie();
  }
}
void draw() {
  pullFac = cosInter((frames-360.0)/360.0);
  highlightWander();
  canvas.beginDraw();
  moveCamera(canvas);
  drawCanvas(canvas, board);
  canvas.endDraw();
  image(canvas, 0, 0);
  drawSide(side, board);
  image(side, W_W, 0);

  frames+=PLAY_SPEED;
  if(SAVE_VIDEO){
    videoExport.saveFrame();
  }
}
void highlightWander() {
  if (frames >= transitionTime) {
    transitionTime = frames+transitionLength;
    for (int d = 0; d < 3; d++) {
      location[1][d] = location[0][d];
    }
    if (RANDOM_WALK == 2) {
      for (int d = 0; d < 3; d++) {
        location[0][d] = (int)random(0, board.getDimSize(d)+1);
      }
    } else if (RANDOM_WALK == 1) {
      Node thisNode = board.getNode(location[0]);
      Node nextNode = thisNode.pickRandomNeighbor();
      for (int d = 0; d < 3; d++) {
        location[0][d] = nextNode.getCoor(d);
      }
    } else {
      pathIndex++;
      for (int d = 0; d < 3; d++) {
        location[0][d] = pathData[pathIndex%pathData.length][d];
      }
    }
  }
}
void processPathData() {
  pathDataStr = loadStrings(PATH_FILENAME);
  pathData = new int[pathDataStr.length][3];
  for (int i = 0; i < pathDataStr.length; i++) {
    String[] parts = pathDataStr[i].split("\t");
    for (int d = 0; d < 3; d++) {
      pathData[i][d] = Integer.parseInt(parts[d]);
    }
  }
}
void processPullData() {
  pullDataStr = loadStrings(PULL_FILENAME);
  pullData = new float[board.getDimSize(2)+1][board.getDimSize(1)+1][board.getDimSize(0)+1][2];
  for (int i = 0; i < pullDataStr.length; i++) {
    String[] parts = pullDataStr[i].split("\t");
    int[] c = new int[3];
    for (int d = 0; d < 3; d++) {
      c[d] = Integer.parseInt(parts[d]);
    }
    pullData[c[2]][c[1]][c[0]][0] = Float.parseFloat(parts[3]);
    pullData[c[2]][c[1]][c[0]][1] = Float.parseFloat(parts[4]);
  }
}
void drawSide(PGraphics c, Board b) {
  float xW = S_W*0.20;
  float moreXOff = 0;
  if (b.getDimSize(0) >= 4) {
    xW = S_W*0.77/b.getDimSize(0);
    moreXOff = -110;
  }
  float Y1 = S_H*0.7;
  float Y2 = S_H*0.3;
  float Y1a = S_H*0.68;
  float Y2a = S_H*0.34;
  c.beginDraw();
  c.background(150, 230, 80);
  c.noStroke();
  c.fill(0, 0, 255);
  c.rect(0, Y2a, c.width, Y1a-Y2a);
  int[] x_offs = {145, 170, 100};
  int[] y_offs = {-75, -135, -75};
  for (int d = 2; d >= 0; d--) {
    int count = b.getDimSize(d);
    for (int i = 0; i < count; i++) {
      c.pushMatrix();
      c.translate(xW*i+x_offs[d]+moreXOff, y_offs[d]);
      if (i < location[0][d] && i < location[1][d]) {
        c.translate(0, Y2);
      } else if (i >= location[0][d] && i >= location[1][d]) {
        c.translate(0, Y1);
      } else if (i >= location[0][d] && i < location[1][d]) {
        c.translate(0, lerp(Y2, Y1, fprog()));
      } else if (i < location[0][d] && i >= location[1][d]) {
        c.translate(0, lerp(Y1, Y2, fprog()));
      } 
      //float wid = (d == 2) ? xW*3 : xW*0.8;
      PImage img = sideImages[d];
      if (d == 2 && b.W >= 4) {
        c.translate(130*i+40, 100, 0);
        c.scale(0.5, 0.5);
      }
      c.image(img, 0, 0, img.width/4, img.height/4);
      c.popMatrix();
    }
  }
  c.fill(0);
  c.textAlign(LEFT);
  int stage = 0;
  if (fprog() < 0.5) {
    stage = 1;
  }
  for (int bank = 0; bank < 2; bank++) {
    for (int d = 0; d < 3; d++) {
      c.fill(b.getDimColor(d));
      c.pushMatrix();
      c.translate(30+230*d, 90+910*bank);
      c.textFont(font, 96);
      int val = location[stage][d];
      if (bank == 1) {
        val = b.getDimSize(d)-val;
      }
      c.text(val, 0, 0);
      c.textFont(font, 48);
      c.text(b.getDimLabel(d), 0, 48);
      c.popMatrix();
    }
  }
  c.endDraw();
}
void moveCamera(PGraphics c) {
  float cameraZ = ((c.height/2.0) / tan(PI*60.0/360.0));
  float fovy = PI/3.0;
  c.perspective(fovy, ((float)c.width/c.height), cameraZ/1000.0, cameraZ*10.0);

  if (LOCK_CAMERA) {
    /*double[] arr = new double[pathData.length];
    for (int i = 0; i < pathData.length; i++) {
      arr[i] = 0;
      arr[i] += 0.06*(pathData[i][0]-board.getDimSize(0)*0.5);
      arr[i] -= 0.002*(pathData[i][1]-board.getDimSize(1)*0.5);
      arr[i] -= 0.002*(pathData[i][2]-board.getDimSize(2)*0.5);
      if(pathData[i][0] == 2){
        if(i < 13){
          arr[i] -= 0.09;
        }else{
          arr[i] += 0.09;
        }
      }
    }
    double pr = (frames/30.0);
    Xang = 1.9*(float)cosArrMod(arr, pr)*PI/2;
    Yang = 0.53*PI/2;*/


    double[][] arr = {{0.3,0.05,-0.25,-0.03},{0.5,0.35,0.45,0.25}};
    double pr = (frames/380.0+0.5);
    Xang = (float)cosArrMod(arr[0],pr)*PI/2;
    Yang = ((float)cosArrMod(arr[1],pr)+0.15)*PI/2;

    //double[] angs = {0.06,-0.04,0.00,0.05,0.175,0.104,0.05,0.25,-0.15,0.03,-0.03};
    //Xang = 2*PI*(float)cosArr(angs,(double)frames/transitionLength/2+0.25);
    //Xang = 2*PI*STARTING_ANGLE+frames*TURN_SPEED;
    //Xang = 2*PI*(0.125-cos(frames*2*PI/600)*0.03);
    //Xang = 2*PI*(0.08-cos((frames/2000.0)*2*PI)*0.10);
    //Xang = -2*PI*cos((frames/800.0)*2*PI)*0.06;
  } else {
    Yang = (mouseY-c.height/2.0)/(height/2.0)*PI/2;
    Xang = (mouseX-c.width/2.0)/(width/2.0)*PI;
  }

  float dis = pow(1.1, zoom) * (c.height/2.0) / tan(PI*30.0 / 180.0);
  float centerX = W_W/2;
  float centerY = W_H/2;
  float centerZ = 0;

  c.camera(centerX, centerY+dis*sin(Yang), 
    centerZ+dis*cos(Yang), 
    centerX, centerY, centerZ, 0, 1, 0);
  c.translate(centerX, centerY, centerZ);
  c.rotateZ(-Xang);
  c.translate(-centerX, -centerY, -centerZ);
}
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoom += e;
}
double cosArr(double[] arr, double x) {
  int x_int = (int)x;
  double x_rem = x%1.0;
  double prog = 0.5-0.5*Math.cos(x_rem*PI);
  double prev = arr[Math.min(Math.max(x_int, 0), arr.length-1)];
  double next = arr[Math.min(Math.max(x_int+1, 0), arr.length-1)];
  return prev + (next-prev)*prog;
}
double cosArrMod(double[] arr, double x) {
  int x_int = (int)x;
  double x_rem = x%1.0;
  double prog = 0.5-0.5*Math.cos(x_rem*PI);
  double prev = arr[x_int%arr.length];
  double next = arr[(x_int+1)%arr.length];
  return prev + (next-prev)*prog;
}
void drawCanvas(PGraphics c, Board b) {
  c.noStroke();
  c.background(bg);

  //c.lights();
  c.scale(1, -1, 1);
  c.directionalLight(128, 128, 128, 0, 0, -1);
  c.directionalLight(128, 128, 128, 0, 0, 1);
  c.ambientLight(128, 128, 128);
  c.lightFalloff(1, 0, 0);
  c.lightSpecular(0, 0, 0);
  c.pushMatrix();
  c.translate(W_W/2-(b.W/2.0-0.3)*DIST, -W_H/2-(b.L/2.0-0.3)*DIST, b.H*Z_SHIFT*DIST);

  drawGridlines(c, b);
  for (int z = 0; z <= b.H; z++) {
    for (int y = 0; y <= b.L; y++) {
      for (int x = 0; x <= b.W; x++) {
        int[] coor = {x, y, z};
        if (board.getSafe(coor) || DRAW_DANGEROUS) {
          drawSphere(c, f(coor), getR(coor), getCol(coor, b));
        }
        board.nodes[z][y][x].drawLines(c);
      }
    }
  }
  //drawGhostClones(c,b);
  if (DRAW_HIGHLIGHT) {
    drawHighlight(c, b);
  }
  drawTags(c, b);
  for (int d = 0; d < 3; d++) {
    drawLabels(c, d);
  }
  c.popMatrix();
}
void drawTags(PGraphics c, Board b) {
  if (DO_PULL_ANIMATION) {
    for (int z = 0; z <= b.H; z++) {
      for (int y = 0; y <= b.L; y++) {
        for (int x = 0; x <= b.W; x++) {
          int[] coor = {x, y, z};
          drawTag(c, f(coor), true, arrToString(coor));
        }
      }
    }
  }
}
float getR(int[] c) {
  int x = c[0];
  int y = c[1];
  float r = RAD*DIST;
  if (PULSATE_NODES) {
    if (x != y && frames >= 48*60 && frames < 60*60) {
      float fac = min(max(-3+4*abs(frames-54.0*60)/(6.0*60), 0), 1);
      r *= fac;
    }
  }
  return r;
}
color getCol(int[] coor, Board b) {
  int x = coor[0];
  int y = coor[1];
  int z = coor[2];
  color col = b.getSafe(coor) ? (z == 0 ? WHITE : BALL_COLOR) : DANGER_COLOR;
  col = b.getEnding(coor) ? END_COLOR : col;
  if (PULSATE_NODES) {
    if ((x == y && frames >= 12*60 && frames < 22*60) ||
      (x < y && frames >= 22*60 && frames < 28*60) ||
      (x > y && frames >= 30*60 && frames < 48*60) ||
      (x == y && frames >= 48*60 && frames < 52*60) ||
      (x == 0 && frames >= 60*60+30 && frames < 63*60+30) ||
      (x == 3 && frames >= 63*60+30 && frames < 65*60+30) ||
      (x%3 == 0 && frames >= 80*60 && frames < 84*60) ||
      (x == y && frames >= 84*60 && frames < 85*60+30) ||
      ((x%3 == 0 || x == y) && frames >= 85*60+30 && frames < 88*60+30) ||
      (x%3 != 0  && x != y && frames >= 88*60+30 && frames < 101*60+30)) {
      col = pulsate(col, color(0, 0, 200), frames/30.0);
    }
    if (x%3 != 0  && x != y && frames >= 101*60+30) {
      col = colorLerp(col, DANGER_COLOR, (frames-(101*60+30))/120.0);
    }
  }
  return col;
}
void drawGhostClones(PGraphics c, Board b) {
  for (int y = 0; y <= b.L; y++) {
    for (int x = 0; x <= b.W; x++) {
      if (y != 0 || x != 0) {

        float timeOffset = (x+(3-y)*4);
        float scaleUp = cosInter(((float)frames-timeOffset*18-510)/90);
        timeOffset = (x+(3-y)*1);
        float scaleDown = 1-cosInter(((float)frames-timeOffset*9-970)/90);
        if (scaleUp > 0) {
          int[] coor = {0, 0, 0};
          c.pushMatrix();
          c.translate(x*DIST*scaleUp, y*DIST*scaleUp, 0);
          drawSphere(c, f(coor), RAD*DIST, color(255, 255, 255));
          board.nodes[0][0][0].drawLinesFade(c, x, y, scaleDown);
          c.popMatrix();
        }
      }
    }
  }
}
color pulsate(color base, color alt, float timer) {
  float prog = 1-2*abs(timer%1.0-0.5);
  return colorLerp(base, alt, prog);
}
color colorLerp(color base, color alt, float prog) {
  float prog_cap = min(max(prog, 0), 1);
  float newR = red(base)+(red(alt)-red(base))*prog_cap;
  float newG = green(base)+(green(alt)-green(base))*prog_cap;
  float newB = blue(base)+(blue(alt)-blue(base))*prog_cap;
  return color(newR, newG, newB);
}
float cosInter(float x) {
  float x_cap = min(max(x, 0), 1);
  return 0.5-0.5*cos(x_cap*PI);
}
void drawGridlines(PGraphics c, Board b) {
  float alpha = 71 * (DO_PULL_ANIMATION ? 1-pullFac : 1);
  c.fill(0, 0, 0, alpha);
  for (int y = 0; y <= b.L; y++) {
    c.rect(0, (y-GRID_THICKNESS/2)*DIST, board.getDimSize(0)*DIST, GRID_THICKNESS*DIST);
  }
  for (int x = 0; x <= b.W; x++) {
    c.rect((x-GRID_THICKNESS/2)*DIST, 0, GRID_THICKNESS*DIST, board.getDimSize(1)*DIST);
  }
  if(DRAW_VERTICAL_GRIDLINES){
    for(int y = 0; y <= b.L; y++){
      for(int x = 0; x <= b.W; x++){
        c.pushMatrix();
        c.translate(x*DIST,y*DIST,0);
        c.rotateZ(-Xang);
        c.rotateX(PI/2);
        c.rect(-GRID_THICKNESS/2*DIST,0,GRID_THICKNESS*DIST,board.getDimSize(2)*DIST);
        c.popMatrix();
      }
    }
  }
}
void drawHighlight(PGraphics c, Board b) {
  int prog = frames-transitionTime+transitionLength;
  float[] highlight_coor = {0, 0, 0};
  String highlight_label = "";
  if (prog < transitionLength/2) {
    highlight_coor = f(interp(location[1], location[0], fprog()));
    highlight_label = arrToString(fprog() >= 0.5 ? location[0] : location[1]);
    float r = HIGHLIGHT_RAD*DIST;
    if (PULSATE_NODES) {
      if (frames >= 68*60 && frames < 79*60) {
        r = RAD*1.01*DIST;
      }
    }
    drawSphere(c, highlight_coor, r, HIGHLIGHT_COLOR);
  } else {
    highlight_coor = f(location[0]);
    highlight_label = arrToString(location[0]);
    if (frames%blinkLength < blinkLength/2 || PULSATE_NODES) {
      drawSphere(c, highlight_coor, HIGHLIGHT_RAD*DIST, HIGHLIGHT_COLOR);
    }
  }
  drawTag(c, highlight_coor, false, highlight_label);
}
void drawTag(PGraphics c, float[] coor, boolean centered, String label) {
  c.noLights();
  c.pushMatrix();
  aTranslate(c, coor);
  c.rotateZ(-Xang);
  c.rotateX(PI+Yang);
  float W = 155;
  float tX = 0;
  if (centered) {
    float S = 0.45;
    c.scale(S);
    tX = -W*0.5;
    c.translate(tX, 18, -0.001-HIGHLIGHT_RAD/S*DIST);
  } else {
    float realX = coor[0];
    float maxX = board.getDimSize(0)*DIST-W*1.1;
    if (realX >= maxX) { // weird edge case to prevent the label from going off the right side of the screen, you can delete this
      tX = maxX-realX;
    }
    //tX = -155;
    c.translate(tX, -HIGHLIGHT_RAD*DIST*2.0, -HIGHLIGHT_RAD*DIST);
  }
  c.textAlign(LEFT);
  c.textFont(font, 48);
  c.fill(255, 255, 255, 159);
  c.rect(0, -39, W, 52);
  c.translate(0, 0, -1);
  c.fill(centered ? color(0, 0, 0) : shade(HIGHLIGHT_COLOR, 0.45));
  c.text(label, 0, 0);
  c.popMatrix();
  c.lights();
}
color shade(color c, float multi) {
  float newR = red(c)*multi;
  float newG = green(c)*multi;
  float newB = blue(c)*multi;
  return color(newR, newG, newB);
}
String arrToString(int[] arr) {
  return "("+arr[0]+", "+arr[1]+", "+arr[2]+")";
}
void aTranslate(PGraphics c, float[] coor) {
  c.translate(coor[0], coor[1], coor[2]);
}
float fprog() {
  int prog = frames-transitionTime+transitionLength;
  return min(max((float)prog/(transitionLength/2), 0), 1);
}
float[] interp(int[] prevLoc, int[] nextLoc, float x) {
  float[] result = new float[prevLoc.length];
  for (int d = 0; d < prevLoc.length; d++) {
    result[d] = prevLoc[d]+(nextLoc[d]-prevLoc[d])*x;
  }
  return result;
}
void drawLabels(PGraphics c, int d) {
  float FONT_SIZE = 48;
  c.noLights();
  c.textFont(font, 48);
  float alpha = (DO_PULL_ANIMATION ? 1-pullFac : 1);
  if (alpha == 0) {
    return;
  }
  c.fill(fade(board.getDimColor(d), alpha));
  c.pushMatrix();
  c.scale(1, -1, 1);
  boolean flip = (d >= 1);
  if (d == 1) {
    c.rotateZ(-PI/2);
  } else if (d == 2) {
    c.rotateZ(-PI/2);
    c.rotateY(-PI/2);
  }
  int dim = board.getDimSize(d);
  c.textAlign(CENTER);
  for (int i = 0; i <= dim; i++) {
    float y = flip ? -RAD*DIST-FONT_SIZE*0.5 : RAD*DIST+FONT_SIZE;
    c.text(i, DIST*i, y);
  }
  c.textAlign(LEFT);
  float y = flip ? -RAD*DIST-FONT_SIZE*2.2 : RAD*DIST+FONT_SIZE*2.7;
  c.text(board.getDimLabel(d), DIST*0.1, y);
  c.noStroke();
  c.pushMatrix();
  y = flip ? -RAD*DIST-FONT_SIZE*1.5 : RAD*DIST+FONT_SIZE*1.5;
  c.translate(DIST*0.9, y);
  c.rect(-DIST*0.8, -FONT_SIZE*0.1, DIST*0.8, FONT_SIZE*0.2);
  c.beginShape();
  c.vertex(0, -FONT_SIZE*0.5);
  c.vertex(FONT_SIZE*0.5, 0);
  c.vertex(0, FONT_SIZE*0.5);
  c.endShape(CLOSE);
  c.popMatrix();
  c.popMatrix();
  c.lights();
}
color fade(color col, float alpha) {
  return color(red(col), green(col), blue(col), 255*alpha);
}
float[] f(int[] a) {
  float[] result = new float[a.length];
  for (int d = 0; d < a.length; d++) {
    result[d] = a[d]*DIST;
  }
  if (DO_PULL_ANIMATION) {
    float[] alt = new float[a.length];
    for (int d = 0; d < 2; d++) {
      alt[d] = pullData[a[2]][a[1]][a[0]][d];
    }
    alt[1] += 1.2*DIST/PULL_DIST; // aligning the graph to the center of the grid
    alt[0] += -5.5+1.2*DIST/PULL_DIST;

    alt[2] = 0;
    for (int d = 0; d < 3; d++) {
      result[d] += (alt[d]*PULL_DIST-result[d])*pullFac;
    }
  }
  return result;
}
float[] f(float[] a) {
  float[] result = new float[a.length];
  for (int i = 0; i < a.length; i++) {
    result[i] = a[i]*DIST;
  }
  return result;
}
void drawSphere(PGraphics c, float[] coords, float r, color col) {
  float x = (float)coords[0];
  float y = (float)coords[1];
  float z = (float)coords[2];
  c.fill(col);
  c.pushMatrix();
  c.translate(x, y, z);
  c.scale(r, r, r);
  c.sphere(1);
  c.popMatrix();
}

void draw_3D_line(PGraphics c, float[] coor1, float[] coor2, float w, color col) {
  int res = 20;
  c.fill(col);
  for (int r = 0; r < res; r++) {
    float angle_1 = ((float)r)/res*2*PI;
    float angle_2 = ((float)r+1)/res*2*PI;
    double[] side_vector_1 = getPerpendicular(coor1, coor2, angle_1, w);
    double[] side_vector_2 = getPerpendicular(coor1, coor2, angle_2, w);
    c.beginShape();
    v(c, coor1[0]+side_vector_1[0], coor1[1]+side_vector_1[1], coor1[2]+side_vector_1[2]);
    v(c, coor1[0]+side_vector_2[0], coor1[1]+side_vector_2[1], coor1[2]+side_vector_2[2]);
    v(c, coor2[0]+side_vector_2[0], coor2[1]+side_vector_2[1], coor2[2]+side_vector_2[2]);
    v(c, coor2[0]+side_vector_1[0], coor2[1]+side_vector_1[1], coor2[2]+side_vector_1[2]);
    c.endShape(CLOSE);
  }
}
void v(PGraphics c, double x, double y, double z) {
  c.vertex((float)(x), (float)(y), (float)(z));
}
double[] getPerpendicular(float[] coor1, float[] coor2, float angle, float w) {
  double[] diff = {coor2[0]-coor1[0], coor2[1]-coor1[1], coor2[2]-coor1[2]};
  double[] perp = {-diff[1], diff[0], 0};
  if (Math.abs(diff[0]) < 0.0001 && Math.abs(diff[1]) < 0.0001) {
    double[] perp2 = {0, -diff[2], diff[1]};
    perp = perp2;
  }
  double[] result = rotateVector(normalize(perp, w), normalize(diff, 1), angle);
  return result;
}
double[] normalize(double[] v, double goalLength) {
  double dist = Math.sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
  double[] result = {goalLength*v[0]/dist, goalLength*v[1]/dist, goalLength*v[2]/dist};
  return result;
}

double[] rotateVector(double[] vector, double[] axis, double theta) {
  double u = axis[0];
  double v = axis[1];
  double w = axis[2];
  double x = vector[0];
  double y = vector[1];
  double z = vector[2];
  double xPrime = u*(u*x + v*y + w*z)*(1d - Math.cos(theta)) 
    + x*Math.cos(theta)
    + (-w*y + v*z)*Math.sin(theta);
  double yPrime = v*(u*x + v*y + w*z)*(1d - Math.cos(theta))
    + y*Math.cos(theta)
    + (w*x - u*z)*Math.sin(theta);
  double zPrime = w*(u*x + v*y + w*z)*(1d - Math.cos(theta))
    + z*Math.cos(theta)
    + (-v*x + u*y)*Math.sin(theta);
  double[] result = {xPrime, yPrime, zPrime};
  return result;
}
