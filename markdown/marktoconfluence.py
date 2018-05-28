#!/usr/bin/python
# 
# based on: https://github.com/dirkk0/Markdown-Converter/blob/master/markdown_converter.py
#
import getopt
import logging
import re
import os
import sys

#
# globals
#

HELP_MSG = """
Usage: marktoconfluence.py [-h|--help] [-d|--debug] -i|--input <input-file>
        -h|--help                 Print this help message and exit.
        -d|--debug                Turn on debugging.
        -i|--input <input-file>   The input file to process.
"""

#
# functions
#
def spacecount(txt):
  chars = list(txt)
  ct = 0
  for char in chars:
    if char == ' ':
      ct += 1
    else:
      break
  
  logging.info("Found %s spaces in: %s" % (ct, txt))
  return ct


def cvttext(txt):
  # replace all hyperlinks
  txt = re.sub(r'\[(.*?)\]\((.*?)\)', r'[\1|\2]', txt)
  
  # replace bold with a dummy string
  txt = re.sub(r'\*\*(.*?)\*\*', r'BOLD\1BOLD', txt)
  txt = re.sub(r'__(.*?)__', r'BOLD\1BOLD', txt)
  
  # replace italics
  txt = re.sub(r'\*(.*?)\*', r'_\1_', txt)
  
  # replace the dummy bold string
  # replace bold
  txt = re.sub(r'BOLD(.*?)BOLD', r'*\1*', txt)
  
  # replace inline code with monospace
  txt = re.sub(r'`(.*?)`', r'{{\1}}', txt)
  
  headings = []

  headings.append( ['######','h6.'] )
  headings.append( ['#####','h5.'] )
  headings.append( ['####','h4.'] )
  headings.append( ['###','h3.'] )
  headings.append( ['##','h2.'] )
  headings.append( ['#','h1.'] )
  
  lines = txt.split('\n')
  
  spacect = 0
  islist = 0
  isquote = 0
  iscode = 0
  outtxt = []
  
  for line in lines:
    outline = line
    
    if line[0:1] == '*':
      # part of a list 
      islist = 1
    elif line[0:1] == '>':
      if isquote == 0:
        isquote = 1
        outline = '{quote}\n'+outline[1:]
      else:
        outline = outline[1:]
    else:
      islist = 0
      if isquote == 1:
        outline = '{quote}\n'+outline
        isquote = 0
    
    if islist == 0:
      if iscode == 1:
        if line[0:1] == ' ' or line[0:1] == '  ':
          pass
        else:
          outline = '{code}\n'+outline
          iscode = 0
      else:
        if line[0:1] == ' ' or line[0:1] == '  ':
          spacect = spacecount(outline)
          outline = '{code}\n'+outline[spacect:]
          iscode = 1
    else:
      if line[0:4] == '      *':
        outline = '****' + outline[4:]
      elif line[0:3]=='    *':
        outline = '***' + outline[3:]
      elif line[0:2] == '  *':
        outline = '**' + outline[2:]
    
    if not re.match(r'^$', line):
      logging.debug("Checking line for headings : %s" % line)
      for heading in headings:
        if re.match(r'^'+heading[0], line):
          outline = re.sub(r'^'+heading[0], heading[1], outline)
          outline = re.sub(heading[0]+'$', '', outline)
          break
    
    if iscode == 1 and not re.match('\{code\}', outline):
      outline = outline[spacect:]
    
    outtxt.append(outline)
    
  return '\n'.join(outtxt)

def cvt(infile):
  try:
    logging.info("Parsing %s" % infile)
    hdle = open(infile, 'r')
    instr = hdle.read()
  except IOError, ioe:
    logging.fatal("Failed to open %s : %s" % (infile, ioe))
    return

  outstr = cvttext(instr)
  
  outfile = infile+".txt"
  logging.info("Writing output to %s" % outfile)
  try:
    hdle = open(outfile, 'w')
    hdle.write(outstr)
  except IOError, ioe:
    logging.fatal("Failed to write output to %s : %s" % (outfile, ioe))

def main(argv=None):
  """
  Main program entry point.
  """
  if argv is None:
    argv = sys.argv
  
  llevel = logging.INFO
  try:
    opts, args = getopt.getopt(argv[1:], "hdi:", [ "help", "debug", "input" ])
  except getopt.error, msg:
    print "%s\n%s" % (str(msg), HELP_MSG)
    return 1

  infile = None
  for option, value in opts:
    if option in ("-h", "--help"):
      print HELP_MSG
      return 1
    elif option in ("-d", "--debug"):
      llevel = logging.DEBUG
    elif option in ("-i", "--input"):
      infile = value
  
  logging.basicConfig(level=llevel,
    format='%(asctime)s: [%(levelname)s] - %(message)s')
  
  if not infile:
    print HELP_MSG
    return 1
  #elif not os.path.exists(infile):
  #  logging.fatal("Input File %s does not exist?" % (infile))
  #  return 1
  
  cvt(infile)


#
# main
#

if __name__ == "__main__": 
  main()

