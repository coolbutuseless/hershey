

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Read a Hershey Font file in .jhf format
#'
#' @param jhf_filename filename
#' @param trim_start = TRUE
#'
#' @return character vector. 1 string per glyph.
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
read_jhf <- function(jhf_filename, trim_start = TRUE) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # One glyph per line.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  jhf <- readLines(jhf_filename)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Find which rows don't start with an integer, and are therefore a
  # continuation of the line above and should be merged with it.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  bad_start <- suppressWarnings(is.na(as.integer(substr(jhf, start = 0, stop = 5))))
  bad_start <- which(bad_start)

  for (ii in rev(bad_start)) {
    jhf[ii - 1] <- paste0(jhf[ii - 1], jhf[ii])
  }

  jhf <- jhf[-bad_start]

  jhf
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Convert a Hershey glyph code to a data.frame
#'
#' A not particularly elegant or fast way to convert a Hershey font code string
#' to a data.frame.
#'
#' @param glyph glyph code character string e.g. "    8  9MWOMOV RUMUV ROQUQ"
#'
#' @return data.frame with x, y and stroke group.
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
convert_glyph_to_df <- function(glyph) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # First 5 chars are the ID (integer)
  # Next 3 chars give the number of vertices as an integer
  # The first 2 points are actual the left + right extents
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  glyph_idx <- substr(glyph, 1, 5)
  Nvertices <- substr(glyph, 6, 8)
  codes     <- substr(glyph, 9, nchar(glyph))
  codes     <- utf8ToInt(codes) - utf8ToInt('R')

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Every pair of characters represents a coordinate pair.
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  x <- codes[c(T, F)]
  y <- codes[c(F, T)]

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # First coordinate is actual left/right information
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  left  <- x[ 1]
  x     <- x[-1]
  right <- y[ 1]
  y     <- y[-1]

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # IF there are no strokes, then just make up a 0 point that
  # should probably never get plotted
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (length(x) == 0) {
    x <- 0L
    y <- 0L
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Data frame of coordinates.
  # Designate which 'stroke' a point belongs to by looking for " R" i.e. (-50, 0)
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  coords <- data.frame(
    x      = x,
    y      = -y,
    left   = left,
    right  = right,
    width  = right - left,
    stroke = cumsum(x == -50 & y == 0)  # " R" is c(-50, 0)
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Now that 'stroke' is added, we can remove the "pen up" commands
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  coords <- coords[!(coords$x == -50 & coords$y == 0),]

  coords$idx <- seq(nrow(coords))

  coords
}




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Read a .jhf Hershey font file as a data.frame
#'
#' @param jhf_filename Hershey font file (.jhf)
#'
#' @return data.frame
#'
#' @import tools
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
convert_hershey_font_to_df <- function(jhf_filename) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Read the jhf file in as a character vector. One string per glyph
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  jhf <- read_jhf(jhf_filename)
  font_name <- tools::file_path_sans_ext(basename(jhf_filename))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Convert each glyph to a data.frame
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  df <- lapply(jhf, convert_glyph_to_df)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Add an index to each glyph
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  df <- mapply(function(x, y) {
    if (!(is.null(x))) {
      x$glyph <- y
    }
    x
  },
  df, seq_along(df),
  SIMPLIFY = FALSE
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Join all glyph data.frames into a font data.frame
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  df <- do.call(rbind, df)
  rownames(df) <- NULL

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Set the font name
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  df$font <- font_name


  df
}












