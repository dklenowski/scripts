import sys
sys.path.append("..")

import unittest
import os
import logging
import colorutils


class ColorTest(unittest.TestCase):
  """
  Tests for colorutils.Color
  """
  def test_init(self):
    color = colorutils.Color()
    self.assertEqual(color.red, 1.0, "incorrect initial red")
    self.assertEqual(color.green, 1.0, "incorrect initial green")
    self.assertEqual(color.blue, 1.0, "incorrect initial blue")

  def test_accessors(self):
    color = colorutils.Color()
    color.red = 0.5
    color.green = 0.4
    color.blue = 0.1
    
    self.assertEqual(color.red, 0.5, "incorrect accessor red")
    self.assertEqual(color.green, 0.4, "incorrect accessor green")
    self.assertEqual(color.blue, 0.1, "incorrect accessor blue")

class ColorMapperTest(unittest.TestCase):
  """
  Tests for ColorMapper
  """
  def test_init(self):
    mapper = colorutils.ColorMapper(300)
    
    color = mapper.color(0)
    self.assertEqual(str(color), "[0.00, 0.00, 1.00]", "incorrect 0 mapping")
    
    color = mapper.color(150)
    self.assertEqual(str(color), "[0.00, 1.00, 0.00]", "incorrect 150 mapping")
    
    color = mapper.color(300)
    self.assertEqual(str(color), "[1.00, 0.00, 0.00]", "incorrect 300 mapping")

  def test_map(self):
    mapper = colorutils.ColorMapper(3)
    colormap = mapper.colormap()
    self.assertEqual(len(colormap), 3, "incorrect size for color map")
    
if __name__ == '__main__':
  logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)
  unittest.main()