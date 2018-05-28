import sys
import os
from optparse import OptionParser, OptionGroup
import logging
from wordpress_xmlrpc import WordPressPage
import wordpress_xmlrpc
import wordpress_xmlrpc.methods
import wordpress_xmlrpc.methods.posts as posts
import markdown
import re

reload(sys)
sys.setdefaultencoding("utf-8")

wp_client = None
dry_run = False


class UploadType:
  POST, PAGE = range(2)

  @staticmethod
  def str(value):
    if value == UploadType.POST:
      return "Post"
    elif value == UploadType.PAGE:
      return "Page"
    else:
      return "Unknown"


def upload(utype, title, categories, tags, content):
  logging.info("uploading post \"%s\"" % title)

  if utype == UploadType.POST:
    p = posts.WordPressPost()
  else:
    p = WordPressPage()

  p.title = title
  p.content = content
  p.post_status = 'publish'

  if utype == UploadType.POST:
    p.terms_names = {
      'post_tag': tags,
      'category': categories
    }

  wp_client.call(posts.NewPost(p))

def delete(postid):
  logging.info("deleting post with id %s" % postid)
  wp_client.call(posts.DeletePost(postid))

def get(utype):
  if utype == UploadType.POST:
    entries = wp_client.call(posts.GetPosts({'post_status':'publish', 'number':10000}))
  else:
    entries = wp_client.call(posts.GetPosts({'post_type': 'page', 'post_status':'publish', 'number':10000}))

  logging.info("parsing %d entries" % len(entries))

  all_posts = {}
  for entry in entries:
    logging.info("found entry %s with title \"%s\"" % (entry.id, entry.title))
    all_posts[entry.title] = { 'id': entry.id, 'content': entry.content }

  return all_posts

def update(utype, path):
  md = markdown.Markdown(extensions = ['markdown.extensions.meta', 'markdown.extensions.fenced_code'])

  cur = get(utype)
  new = {}
  files = os.listdir(path)
  for name in files:
    mpath = os.path.join(path, name)

    title = name
    title = title.replace("-", " ")
    title = title.replace(".mdown", "")

    content = md.convert(open(mpath, 'r').read())
    if title in cur:
      if same(content, cur[title]['content']):
        continue

      logging.info("updated content for %s" % title)
      #logging.debug("OLD ********\n%s\n********\n" % cur[title]['content'])
      #logging.debug("NEW ********\n%s\n********\n" % content)

      if not dry_run:
        delete(cur[title]['id'])

    # if we get to here, add it so we can do a bulk upload
    meta = md.Meta
    if meta is None:
      logging.fatal("failed to find metadata for %s" % mpath)
      continue
    elif not 'categories' in meta:
      logging.fatal("no categories defined for %s" % mpath)
      continue
    elif not 'tags' in meta:
      logging.fatal("no tags defined for %s" % mpath)
      continue

    new[title] = { 'categories':meta['categories'], 'tags':meta['tags'], 'content':content }

  if dry_run:
    return

  for title in new:
    uploadpost(UploadType, title, new[title]['categories'], new[title]['tags'], new[title]['content'])


def same(str1, str2):
  p = re.compile("\s+")

  str1nospace = re.sub(p, '', str1)
  str2nospace = re.sub(p, '', str2)

  return str1nospace == str2nospace

def main():
  global wp_client
  global dry_run

  op = OptionParser()

  op.add_option('', '--dryrun', action="store_true", help="perform a dry-run")
  op.add_option('', '--directory', metavar="DIRECTORY", help="directory to parse")
  op.add_option('', '--url', metavar="URL", help="the URL to connect to")
  op.add_option('', '--username', metavar="USERNAME", help="username to connect to URL with")
  op.add_option('', '--password', metavar="PASSWORD", help="password to connect to URL with")

  opts, args = op.parse_args()

  if not opts.directory:
    print "you must specify a directory?"
    op.print_usage()
    sys.exit(1)
  elif not opts.url:
    print "you must specify a url?"
    op.print_usage()
    sys.exit(1)
  elif not opts.username:
    print "you must specify a username?"
    op.print_usage()
    sys.exit(1)
  elif not opts.password:
    print "you must specify a password?"
    op.print_usage()
    sys.exit(1)

  logging.basicConfig(level = logging.DEBUG, format = "%(asctime)s: [%(levelname)s] - %(message)s")

  if opts.dryrun:
    logging.info("performing dry run!")
    dry_run = True

  url = "%s%s" % (opts.url, 'xmlrpc.php')
  postpath = os.path.join(opts.directory, 'posts')
  pagepath = os.path.join(opts.directory, 'pages')

  wp_client = wordpress_xmlrpc.Client(url, opts.username, opts.password)

  logging.info("sending posts from %s to %s" % (postpath, url))
  update(UploadType.POST, postpath)

  logging.info("sending pages from %s to %s" % (pagepath, url))
  update(UploadType.PAGE, pagepath)


#
# main
#
if __name__ == '__main__':
  sys.exit(main())