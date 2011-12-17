import processing.opengl.*;
import unlekker.util.*;
import unlekker.modelbuilder.*;


MouseNav3D nav;
PImage img;
UGeometry model;
int scan_spacing = 2;
int spacing = scan_spacing/2;
int backing_depth = 10;

int zheight = 20;

int getZ(int x, int y) {
  if (img.get(x, y) == -1) {
    return zheight;
  } 
  else {
    return 0;
  }
}

void setup() {

  model = new UGeometry();
  model.beginShape(TRIANGLES);

  img = loadImage("bitmap.png");
  //size(img.width, img.height, OPENGL);
  size(800, 800, P3D);

  // add MouseNav3D navigation
  nav=new MouseNav3D(this);
  nav.trans.set(width/2, height/2, 0);
  smooth();



  // This pass reduces likelihood of non-manifoldness

  for (int y = 0; y < img.width; y += scan_spacing) {
    for (int x = 0; x < img.height; x += scan_spacing) {
      if (img.get(x, y) != -1) {

        /* Check each direction for blank neighbors */
        if (img.get(x, y + scan_spacing) == -1) { // north

          if (img.get(x + scan_spacing, y) == -1) { // hmm. nothing to the east
            if (img.get(x + scan_spacing, y + scan_spacing) != -1) { // but something to the NE!
              img.set(x, y + scan_spacing, 1); // N
              img.set(x + scan_spacing, y, 1); // E
            }
          }
          if (img.get(x - scan_spacing, y) == -1) { // west
            if (img.get(x - scan_spacing, y + scan_spacing) != -1) { // but something to the NW!
              img.set(x, y + scan_spacing, 1); // N
              //img.set(x - scan_spacing, y, 1); // W
            }
          }
        }


        if (img.get(x, y - scan_spacing) == -1) { // south

          if (img.get(x + scan_spacing, y) == -1) { // hmm. nothing to the east
            if (img.get(x + scan_spacing, y - scan_spacing) != -1) { // but something to the SE!
              //img.set(x, y - scan_spacing, 1); // S
              img.set(x + scan_spacing, y, 1); // E
            }
          }
          if (img.get(x - scan_spacing, y) == -1) { // west
            if (img.get(x - scan_spacing, y - scan_spacing) != -1) { // but something to the SW!
              //img.set(x, y - scan_spacing, 1); // S
              //img.set(x - scan_spacing, y, 1); // W
              img.set(x, y, -1); // clear this one.
            }
          }
        }
      }
    }
  }
  //image(img, 0, 0);

  for (int y = 0; y < img.width; y += scan_spacing) {
    for (int x = 0; x < img.height; x += scan_spacing) {
      
      int x_start;
      if (img.get(x, y) != -1) {
        
        x_start = x;
        //while (img.get(x, y + scan_spacing) != -1
        //&& img.get(x, y - scan_spacing) != -1) {
        //  x += spacing;
        //} 
        
        /* We're going to flip this later, so zheight is actually the bottom */
        UVec3 nw_bot = new UVec3(img.width-(x_start - spacing), img.height - (y+spacing), zheight);
        UVec3 ne_bot = new UVec3(img.width-(x+spacing), img.height - (y+spacing), zheight);
        UVec3 sw_bot = new UVec3(img.width-(x_start - spacing), img.height - (y-spacing), zheight);
        UVec3 se_bot = new UVec3(img.width-(x+spacing), img.height - (y-spacing), zheight);

        UVec3 nw_top = new UVec3(img.width-(x_start - spacing), img.height - (y+spacing), 0);
        UVec3 ne_top = new UVec3(img.width-(x+spacing), img.height - (y+spacing), 0);
        UVec3 sw_top = new UVec3(img.width-(x_start - spacing), img.height - (y-spacing), 0);
        UVec3 se_top = new UVec3(img.width-(x+spacing), img.height - (y-spacing), 0);

        /* Add a cube face for this pixel */
        model.addFace(nw_top, ne_top, sw_top);
        model.addFace(ne_top, se_top, sw_top);

        /* Close the bottom */
        model.addFace(ne_bot, nw_bot, sw_bot);
        model.addFace(se_bot, ne_bot, sw_bot);

        /* Check each direction for blank neighbors */
        if (img.get(x, y + scan_spacing) == -1) { // north
          model.addFace(nw_top, nw_bot, ne_top);
          model.addFace(nw_bot, ne_bot, ne_top);
        }
        if (img.get(x, y - scan_spacing) == -1) { // south
          model.addFace(sw_top, se_top, sw_bot);
          model.addFace(sw_bot, se_top, se_bot);
        }
        if (img.get(x + scan_spacing, y) == -1) { // east
          model.addFace(se_top, ne_top, se_bot);
          model.addFace(se_bot, ne_top, ne_bot);
        }
        if (img.get(x_start - scan_spacing, y) == -1) { // west
          model.addFace(nw_top, sw_top, nw_bot);
          model.addFace(nw_bot, sw_top, sw_bot);
        }
      }
    }
  }

  model.calcBounds(); // <9>
  model.translate(0, 0, -zheight); // <10>
  model.translate(img.width/-2, img.height/-2, 0); // <10>


  float modelWidth = (model.bb.max.x - model.bb.min.x); // <11>
  float modelHeight = (model.bb.max.y - model.bb.min.y);

  //    UGeometry backing = Primitive.box(modelWidth/2, modelHeight/2, 10); // <12>
println(modelWidth);
  UGeometry backing = Primitive.cylinder((modelWidth/2) * 1.1, backing_depth, 20, true); // <12>
  backing.rotateX(radians(90));
  backing.translate(0, 0, -3);
  model.add(backing);

  model.translate(0, 0, -3); // <10>

  model.scale(0.10);  // <13>
  model.rotateY(radians(180));
  model.toOrigin();

  model.endShape(); // <14>
}

void draw() {
  background(100);

  lights();

  // call MouseNav3D transforms
  nav.doTransforms();
  fill(255, 100, 0);

  model.draw(this);
}


public void keyPressed() {
  nav.keyPressed();

  if (key=='s') {
    SimpleDateFormat logFileFmt = 
      new SimpleDateFormat("'scan_'yyyyMMddHHmmss'.stl'");
    model.writeSTL(this, logFileFmt.format(new Date()));
  }
}

public void mouseDragged() {
  nav.mouseDragged();
}

