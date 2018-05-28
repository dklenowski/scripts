"""
Camera tracks a position, orientation and zoom level, and applies openGL
transforms so that subsequent renders are drawn at the correct place, size
and orientation on screen
"""
from __future__ import division
from math import sin, cos

from pyglet.gl import (
  glLoadIdentity, glMatrixMode, gluLookAt, glViewport, gluPerspective, glScalef,
  GL_MODELVIEW, GL_PROJECTION,
)


class Target(object):
  def __init__(self, camera):
    self._x, self._y, self._z = camera.x, camera.y, camera.z

  @property
  def x(self):
    return self._x
  
  @x.setter
  def x(self, x):
    self._x = x

  @property
  def y(self):
    return self._y
  
  @y.setter
  def y(self, y):
    self._y = y

  @property
  def z(self):
    return self._z
  
  @z.setter
  def z(self, z):
    self._z = z

  def __str__(self):
    return "x=%s y=%s z=%s" % ( str(self._x), str(self._y), str(self._z) )

class Camera(object):
  def __init__(self, position=None, fov=None, near=None, far=None, scalex=None, scaley=None, scalez=None):
    if position is None:
      position = (0, 0, 0)
    if fov is None:
      fov = 60
    if near is None:
      near = 500
    if far is None:
      far = 1200
    if scalex is None:
      scalex = 1.0
    if scaley is None:
      scaley = 1.0
    if scalez is None:
      scalez = 1.0
    
    self._x, self._y, self._z = position
    self._zoom = 1
    self._fov = fov
    self._near = near
    self._far = far
    self._scalex = scalex
    self._scaley = scaley
    self._scalez = scalez
    self._target = Target(self)

  @property
  def x(self):
    return self._x
  
  @property
  def y(self):
    return self._y
  
  @property
  def z(self):
    return self._z
  
  def reset(self, position):
    self._x, self._y, self._z = position
    self._zoom = 1

  def zoomIn(self):
    if (self._zoom <= 0.2):
      return
      
    self._zoom -= 0.1
  
  def zoomOut(self):
    self._zoom += 0.1
  
  def moveLeft(self):
    self._x -= 10
    self._y -= 10
  
  def moveRight(self):
    self._x += 10
    self._y += 10
  
  def lookAt(self, x, y, z):
    self._target.x = x
    self._target.y = y
    self._target.z = z

  def focus(self, width, height):
    aspect = width/height
    
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity() 
    
    glViewport(0, 0, width, height)
    gluPerspective(self._fov*self._zoom, aspect, self._near, self._far)
    glScalef(self._scalex, self._scaley, self._scalez)
    
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    gluLookAt(
      self._x, self._y, self._z,
      self._target.x, self._target.y, self._target.z, 
      0.0, 1.0, 0.0)

  def __str__(self):
    return "Camera: x=%d y=%d z=%d [fov=%d near=%d far=%d] [scalex=%d scaley=%d scalez=%d] [target=%s]" % (
      self._x, self._y, self._z, 
      self._fov, self._near, self._far,
      self._scalex, self._scaley, self._scalez,
      str(self._target) )
