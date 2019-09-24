

#' Hershey vector fonts as a single data.frame
#'
#' @format data.frame of all hershey vector fonts
#' \describe{
#'   \item{x,y}{coordinates of endpoints of a single line segment. A stroke consistes of multiple line segements. A glyph consistes of multiple strokes.}
#'   \item{left,right}{Plotting extents of individual glyph}
#'   \item{width}{Width of individual glyph}
#'   \item{stroke}{Index of the stroke within this glyph}
#'   \item{idx}{Index of the point within this glyph}
#'   \item{glyph}{Index of the glyph within this font}
#'   \item{font}{Font name}
#'   \item{ascii}{ASCII code. Set to -1 if it doesn't match a standard ASCII character}
#'   \item{char}{ASCII character representation e.g. 'a'.  Set to empty string if doesn't match a standard ASCII character}
#' }
"hershey"


#' Hershey vector fonts as a list of character strings of the original glyph encodings
#'
#' See vignette for a description of this format.
"hershey_raw"

#' Hershey vector fonts as a list of character strings of SVG paths for each glyph
"hershey_svg"

