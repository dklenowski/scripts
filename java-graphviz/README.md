javadot
=======

Requires http://search.cpan.org/~rsavage/GraphViz/lib/GraphViz.pm

```
perl -MCPAN -e "install GraphViz2"
```

e.g.

```
perl generate.pl -s /workspace-java/foobar/src/main/java/ -p com.orbious \
-o class.png -i com.orbious.foobar.AppConfig,com.orbious.util
```
    
## Mac Notes

On Mac's, `GraphViz2` requires a newer version of Perl than the one supplied by Apple.
The easiest way is to install ActivePerl, update your path and install `GraphViz2`

```
PATH=/usr/local/ActivePerl-5.16/bin:$PATH
export PATH
```
