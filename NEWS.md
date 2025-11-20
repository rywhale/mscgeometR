# mscgeometR 0.1.2

## Breaking Changes
* `geomet_wcs_data` will now error out if a query fails. Previously this would
  silently return a malformed file which could give the impression that the query
  had succeeded until you actually tried to read the data in. This should allow for 
  much easier handling of query errors (#3)

## Small Stuff
* Swap to using `httr2` for all queries (#4)
* Use `terra` in examples instead of `raster` (#6)
* WCS queries now respect format set it in query parameters. The queries
will still produce `.tiff`formatted files by default if no format is explicitly
set
  * In reality, Geomet only supports `image/tiff` and `image/netcdf` so this just
  allows you to grab `.nc` files instead of `.tiff` if desired
* Fix API request pagination

# mscgeometR 0.1.1

* Added support for querying WCS layers requiring authentication

# mscgeometR 0.1.0

* First iteration of package
* Added a `NEWS.md` file to track changes to the package.
* Add contribution guidelines
