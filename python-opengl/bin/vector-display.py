#!/usr/bin/env python
# encoding: utf-8
"""
vector-display.py

Created by dave on 2011-01-01.
Copyright (c) 2011 __MyCompanyName__. All rights reserved.
"""
import sys
import os

sys.path.append( 
  os.path.normpath( 
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "../src") ))


import getopt
import logging
import csv
import pyglet
import pyglet.window
import pyglet.event
import pyglet.clock
from pyglet.gl import *
import colorutils
import camera

##
# constants/globals
## 

width = 1280
height = 720
x_axis_length = 200
y_axis_length = 200
z_axis_length = 200
camera_x = 300
camera_y = 300
camera_z = 600
scene_scale = 1

points = None
colormap = None
depthgap = 50
inputfile = None

pyglet.options['debug_gl'] = False
window = pyglet.window.Window(width=width, height=height, resizable=True, visible=False)

HELP_MSG = """
Usage: vector-display.py [-h|--help] -i|--input <file>
        -h|--help           Print this help message and exit.
        -i|--input <file>   The input file.
"""

GUI_HELP_MSG = """
-------------------------------------------------------------------
| ESC          | Close window.                                    |
| Up Arrow     | Zoom in.                                         |
| Down Arrow   | Zoom Out.                                        |
| Left Arrow   | Move Left.                                       |
| Right Arrow  | Move Right.                                      |
| r|R          | Reset Camera.                                    |
| s|S          | Save display (saved to the inputfile directory). |
| h|H          | Print this help message.                         |
-------------------------------------------------------------------
"""

##
# classes
##

"""
Generic Usage exception.
"""
class Usage(Exception):
  def __init__(self, msg):
    self.msg = msg

"""
A simple buffer.
"""
class Points(object):
  def __init__(self, filename):
    self._filename = filename
    self._maxdepth = 0
    self._points = []
  
  def parse(self):
    reader = csv.reader(open(self._filename, 'rb'))
    ct = -1
    for row in reader:
      ct += 1
      if row[0].startswith('#'):
        continue
      
      if len(row) == 6:
        self._points.append( (int(row[0]), int(row[1]), int(row[2]), 
            int(row[3]), int(row[4]), int(row[5])) )
        # we are colorizing in the x direction
        depth = (int(row[3])/depthgap)+1
        if depth > self._maxdepth:
          logging.info("Setting maxdepth to %d" % depth)
          self._maxdepth = depth
      else:
        logging.fatal("Invalid row %d:%s" % (ct, row))
  
  @property
  def maxdepth(self):
    return self._maxdepth
  
  @property
  def points(self):
    return self._points

##
# window events
##

@window.event
def on_resize(w, h):
  global width, height, scene_changed
  
  width = w
  height = h
  if height == 0:
    height = 1

  camera.focus(width, height)
  
  window.invalid = True
  return pyglet.event.EVENT_HANDLED

@window.event
def on_draw():
  window.clear()

  logging.info("on_draw: %s" % str(camera))
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
  glLoadIdentity()

  camera.lookAt(0, 0, 0)
  camera.focus(width, height)
  
  drawAxes()
  drawPoints()

  return pyglet.event.EVENT_HANDLED

@window.event
def on_key_press(symbol, modifiers):
  if symbol == pyglet.window.key.ESCAPE:
    window.close()
  elif symbol == pyglet.window.key.UP:
    camera.zoomIn()
  elif symbol == pyglet.window.key.DOWN:
    camera.zoomOut()
  elif symbol == pyglet.window.key.LEFT:
    camera.moveLeft()
  elif symbol == pyglet.window.key.RIGHT:
    camera.moveRight()
  elif symbol == pyglet.window.key.R:
    camera.reset((camera_x, camera_y, camera_z))
  elif symbol == pyglet.window.key.S:
    saveDisplay()
  elif symbol == pyglet.window.key.H:
    print GUI_HELP_MSG

  window.invalid = True
  return pyglet.event.EVENT_HANDLED

@window.event
def on_mouse_motion(x, y, dx, dy):
  window.invalid = False

##
# drawing
##

def init():
  glShadeModel(GL_SMOOTH)
  glClearColor(0.0, 0.0, 0.0, 0.0)
  glClearDepth(1.0)
  #glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)
  
def drawAxes():
  # xaxis green
  pyglet.graphics.draw(2, GL_LINES, 
    ('v3f', (0.0, 0.0, 0.0, x_axis_length, 0.0, 0.0)),
    ('c3B', (0, 255, 0, 0, 255, 0)))

  # y axis blue
  pyglet.graphics.draw(2, GL_LINES, 
    ('v3f', (0.0, 0.0, 0.0, 0.0, y_axis_length, 0.0)),
    ('c3B', (0, 0, 255, 0, 0, 255)))

  # z axis red
  pyglet.graphics.draw(2, GL_LINES, 
    ('v3f', (0.0, 0.0, 0.0, 0.0, 0.0, z_axis_length)),
    ('c3B', (255, 0, 0, 255, 0, 0)))

def drawPoints():
  pts = points.points
  for pt in pts:
    #logging.debug("startx=%d starty=%d startz=%d endx=%d endy=%d endz=%d" % (
    #    pt[0], pt[1], pt[2], pt[3], pt[4], pt[5]) )
    #logging.debug("startcolor=%s endcolor=%s" % (str(colormap[pt[0]]), str(colormap[pt[3]])) )

    glBegin(GL_LINES)
    
    glColor3f(colormap[pt[0]].red, colormap[pt[0]].green, colormap[pt[0]].blue)
    glVertex3f(pt[0], pt[1], pt[2])
    
    glColor3f(colormap[pt[3]].red, colormap[pt[3]].green, colormap[pt[3]].blue)
    glVertex3f(pt[3], pt[4], pt[5])
    
    glEnd()


def saveDisplay():
  ct = 0
  tmpfile = os.path.abspath(inputfile).replace('.', '_')
  outputfile = "%s_%s.%s" % (tmpfile, str(ct), "png")
  
  while os.path.exists(outputfile):
    ct += 1
    outputfile =  "%s_%s.%s" % (tmpfile, str(ct), "png")
  
  logging.info("Saving screenshot to %s" % outputfile)
  pyglet.image.get_buffer_manager().get_color_buffer().save(outputfile)

##
# miscellaneous
##

def genColorMap():
  global points, colormap
  colormap = {}
  mapper = colorutils.ColorMapper(points.maxdepth)
  cmap = mapper.colormap()
  for depth in range(len(cmap)):
    scaleddepth = depth*depthgap
    logging.info("Adding color for depth %d to scaled depth %d" % (depth, scaleddepth) )
    colormap[scaleddepth] = cmap[depth]

##
# main
##

def main(argv=None):
  global camera, inputfile, points, colormap
  if argv is None:
    argv = sys.argv
  
  logging.basicConfig(level = logging.INFO, 
      format = "%(asctime)s: [%(levelname)s] - %(message)s")

  try:
    try:
      opts, args = getopt.getopt(argv[1:], "hi:", [ "help", "input" ])
    except getopt.error, msg:
      raise Usage(msg)
      return 1

    if len(opts) == 0:
      raise Usage(HELP_MSG)

    for option, value in opts:
      if option in ("-h", "--help"):
        raise Usage(HELP_MSG)
      elif option in ("-i", "--input"):
        inputfile = value
    
    if not inputfile:
      raise Usage("Must specify an input file\n\n%s" % HELP_MSG)
    
  except Usage, err:
    print str(err.msg)
    return 1

  camera = camera.Camera((camera_x, camera_y, camera_z)) 
  
  points = Points(inputfile)
  points.parse()
  genColorMap()

  init()
  window.set_visible()
  pyglet.clock.set_fps_limit(1)
  pyglet.app.run()

  return 0

if __name__ == "__main__": 
  sys.exit(main())
