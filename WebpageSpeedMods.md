# Introduction #

The following are some tools I've recently used to help improve the load times of our mapping pages. These are based mainly on a soup of Openlayers, GeoExt/ExtJS.

## Reducing Javascript Library Sise ##
My first step was to try and get the libraries I use to a smaller size by removing the objects I wasn't using.
  * OpenLayers
> In the build directory of OpenLayers, there are .cfg that allow you to customize the individual .js files compiled into the final Openlayers javascript. I greped the javascript files I create to find which Openlayers objects I used, then included those library files into a custom .cfg file. The build script parses and includes any required objects automatically.

  * ExtJS
> ExtJS allows you to build a custom library as well, I have not done this yet and still use the full library.

## Javascript Minimizer ##
For better server response, concatenate javascript files into one file, where possible, and then minify the code. This works for CSS files as well, although I did run into some issue trying to combine the ExtJS.css file with my CSS files.

I used the [yuicompressor](http://developer.yahoo.com/yui/compressor/) from Yahoo to compress multiple javascript and css files.

To concatenate and compress the files in one pass, I used this [script](http://lowfatcats.com/blog/1-tutorial/18-how-to-optimize-javascript-css-linux-using-yui-compressor.html).

## Apache Configuration ##
The [mod\_deflate](http://httpd.apache.org/docs/2.0/mod/mod_deflate.html) module enables server side file compression for browser which support compression.