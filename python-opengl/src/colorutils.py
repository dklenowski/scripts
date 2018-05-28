# a simple color ramp
# adapted to python from 
# http://local.wasp.uwa.edu.au/~pbourke/texture_colour/colourramp/

class Color(object):
  def __init__(self):
    self._red = 1.0
    self._green = 1.0
    self._blue = 1.0
  
  @property 
  def red(self):
    return self._red
  
  @red.setter
  def red(self, red):
    self._red = red

  @property 
  def green(self):
    return self._green
  
  @green.setter
  def green(self, green):
    self._green = green
  
  @property 
  def blue(self):
    return self._blue
  
  @blue.setter
  def blue(self, blue):
    self._blue = blue
  
  def __str__(self):
    return "[%.2f, %.2f, %.2f]" % (self._red, self._green, self._blue)

class ColorMapper(object):

  def __init__(self, maxdepth):
    self._maxdepth = maxdepth
  
  @property
  def maxdepth(self):
    return self._maxdepth
  
  @maxdepth.setter
  def maxdepth(self, maxdepth):
    self._maxdepth = maxdepth

  def colormap(self):
    a = []
    for i in range(self._maxdepth):
      a.append(self.color(i))
    
    return a

  def color(self, depth):
    maxdepth = self._maxdepth
    color = Color()

    if depth > maxdepth:
      depth = maxdepth
    
    if depth < (0.25 * maxdepth):
      color.red = 0
      color.green = 4 * depth/maxdepth
    elif depth < (0.5 * maxdepth):
      color.red = 0
      color.blue = 5 + (0.25 * (maxdepth - depth))/maxdepth
    elif depth < (0.75 * maxdepth):
      color.red = 4 * (depth - 0.5 * maxdepth)/maxdepth
      color.blue = 0
    else:
      color.green = 5 * (0.75 * (maxdepth - depth))/maxdepth
      color.blue = 0
    
    return color
    
