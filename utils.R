# Define our own function to efficiently calculate distances

#' Haversine formula
#'
#'  Source https://stackoverflow.com/a/42014364
#'
#'  Determine the great-circle distance between two points on a sphere
#'
#'  @param lat_from Latitude 1
#'  @param lon_from Longitude 1
#'  @param lat_to Latitude 2
#'  @param lon_to Longitude 2
#'  @param r Equatorial radius of Earth (m)
#'  @return Distance in meters
dt_haversine <- function(lat_from, lon_from, lat_to, lon_to, r = 6378137) {
  radians <- pi / 180
  lat_to <- lat_to * radians
  lat_from <- lat_from * radians
  lon_to <- lon_to * radians
  lon_from <- lon_from * radians
  d_lat <- (lat_to - lat_from)
  d_lon <- (lon_to - lon_from)
  a <- (sin(d_lat / 2) ^ 2) + (cos(lat_from) * cos(lat_to)) * (sin(d_lon / 2) ^ 2)
  return(2 * atan2(sqrt(a), sqrt(1 - a)) * r)
}