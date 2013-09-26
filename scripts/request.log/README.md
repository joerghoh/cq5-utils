# Graphing a request.log file

Graphing a request.log file requires 2 files:
* the requestlog.pm file as a helper library to do the actual parsing
* the graph-request-log.pl file

Although you can put the requestlog.pm file to your perl module library, it also works if it just sits next the graph-request-log.pl file.


## Requirements

The script creates output, which can be fed directly to the gnuplot program. It contains all relevant graphing information including the data.

## Usage

the most basic usecase is something like this:

``` 
perl graph-request-log.pl request.log | gnuplot 
```

Then you will find a file called "output.png" in the current directory.

All parameters (you can also get them using "perl graph-request-log.pl --help":

```
  Print a graphical version of a CQ5 request.log file

  $0 [options] file ...
  --title TITLE         - the title of the output graph
  --mime MATCH          - only analyze requests which have the MATCHing mime type set (regexp allowed)
  --statuscode STATUS   - the numerical HTTP statuscode, which must match (default: all match)
  --path-match MATCH    - only analyze requests which URL does match the regular expression MATCH
  --width=WIDTH         - the width of the generated image in pixels, default is 770
  --auto                - enable auto tuning to set various settings to reasonable values
  --output FILENAME     - the name of the file where to put the resulting graph
  --help                - print this and exit

  Filtering:
  --mime, --path-match and --statuscode are additive.


  all files are evaluated and integrated in this output

  result will be displayed on STDOUT, which you can pipe directly into gnuplot
  without any further parameters (the final image filename can be given to the --output parameter)

``` 







