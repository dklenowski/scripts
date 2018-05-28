#!/usr/bin/env ruby
require 'rubygems'
require 'redcarpet'
require 'pdfkit'

#
# globals
#

#
# subs
#

def log(code, msg)
  puts "[#{code.upcase}] - #{msg}"
end

#
# main
#
infile = ARGV[0]
if infile.nil? 
  log 'fatal', 'Missing input file?'
  exit 1
end

log 'info', "Processing #{infile}"

stylestr = IO.read( File.expand_path(File.dirname(__FILE__)) + '/pdf.css')

markstr = IO.read(infile)
if markstr.nil?
  log 'fatal', "Failed to read input from #{infile}"
  exit 1
end

# generate an index
md = Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC.new())
indexstr = md.render(markstr)

# now generate the remainder of the text
md = Redcarpet::Markdown.new(
       Redcarpet::Render::HTML.new(:with_toc_data => true, :hard_wrap => true) )
htmlstr = md.render(markstr)
if htmlstr.nil?
  log 'fatal', "Failed to convert markdown to html?"
  exit 1
end

outfile="#{infile}.pdf"
log 'info', "Writing to pdf #{outfile}"

kit = PDFKit.new(stylestr+indexstr+htmlstr, :print_media_type => true)
file = kit.to_file(outfile)
