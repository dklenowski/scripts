#!/usr/bin/env ruby
require 'rubygems'
require 'redcarpet'
require 'pdfkit'

#
# globals
#

stylestr = <<-eos
<style media="all" type="text/css">
body {
  margin: 0 auto;
  color: #444444;
  line-height: 1;
  padding: 30px;
}

h1, h2, h3, h4 {
  color: #111111;
  font-weight: 400;
}

h1, h2, h3, h4, h5, p {
  margin-bottom: 24px;
  padding: 0;
}

h1 {
  page-break-before: always;
  font-size: 48px;
}

h2 {
  page-break-before: always;
  font-size: 36px;
  /* The bottom margin is small. It's designed to be used with gray meta text
   * below a post title. */
  margin: 24px 0 6px;
}

h3 {
  font-size: 32px;
}

h4 {
  font-size: 28px;
}

h5 {
  font-size: 24px;
}

a {
  color: #0099ff;
  margin: 0;
  padding: 0;
  vertical-align: baseline;
}

a:hover {
  text-decoration: none;
  color: #ff6600;
}

a:visited {
  color: purple;
}

ul, ol {
  padding: 0;
  margin: 0;
}

li {
  line-height: 24px;
}

li ul, li ul {
  margin-left: 24px;
}

p, ul, ol {
  font-size: 16px;
  line-height: 24px;
  max-width: 540px;
}

pre {
  padding: 0px 24px;
  max-width: 800px;
  white-space: pre-wrap;
}

code {
  font-family: Consolas, Monaco, Andale Mono, monospace;
  line-height: 1.5;
  font-size: 13px;
}

aside {
  display: block;
  float: right;
  width: 390px;
}

blockquote {
  border-left:.5em solid #eee;
  padding: 0 2em;
  margin-left:0;
  max-width: 476px;
}

blockquote  cite {
  font-size:14px;
  line-height:20px;
  color:#bfbfbf;
}

blockquote cite:before {
  content: '\2014 \00A0';
}

blockquote p {  
  color: #666;
  max-width: 460px;
}

hr {
  width: 540px;
  text-align: left;
  margin: 0 auto 0 0;
  color: #999;
}
</style>
eos



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
