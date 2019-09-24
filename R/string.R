

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Create a data.frame of glyph strokes for the given string
#'
#' An error will occur if the string includes ascii which is not part of the font.
#'
#' @param text text string
#' @param font font name. default 'rowmant'
#'
#' @return data.frame with coorindates for all glyphs with characters
#' offset appropriately. 'char_idx' is the index of the character within the
#' given 'text' string.
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
create_string_df <- function(text, font = 'rowmant') {

  hershey <- hershey::hershey

  if (!font %in% hershey$font) {
    stop("create_string_df(): No such font: ", font, call. = FALSE)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Select the requested font.
  # Set an ordering so stuff doesn't get messed up during the merge
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  font_df <- hershey[hershey$font == font, ]

  ascii  <- utf8ToInt(text)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Check the font has the required characters
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  missing <- unique(ascii[!ascii %in% font_df$ascii])
  if (length(missing) > 0) {
    stop("create_string_df(): Requested ascii characters that don't exist in font: ",
         font, " ", deparse(intToUtf8(missing)), call. = FALSE)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create a data.frame of all the requested characters and their index within
  # the initial text
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  text_df <- data.frame(
    ascii    = ascii,
    char_idx = seq_along(ascii)
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create a dataset with all the requested characters and the glyphs which
  # generate them
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  string_df <- merge(text_df, font_df, sort=FALSE)
  string_df <- string_df[with(string_df, order(char_idx, stroke, idx)), ]

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Need to work out how far to offset characters after the first character
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  offsets_df <- unique(string_df[,c('char_idx', 'char', 'left', 'right')])

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # The difference between centres of two characters is the sum of the right boundary of
  # first and the left_boundary of the second character
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  kern <- with(offsets_df, head(right, -1) - tail(left, -1))
  kern <- c(0, kern)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Cumulatively offset all characters
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  offsets_df$offset <- cumsum(kern)
  string_df        <- merge(string_df, offsets_df, sort=FALSE)
  string_df$x      <- string_df$x + string_df$offset

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Merging totally borks the order, so put everything back in place
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  string_df   <- string_df[with(string_df, order(char_idx, stroke, idx)), ]

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # add an overall stroke index
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  string_df$stroke_idx <- as.integer(interaction(string_df$stroke, string_df$char_idx))

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Make it a tibble and return
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  class(string_df) <- c('tbl_df', 'tbl', 'data.frame')
  string_df
}



if (FALSE) {

  text = "Great White Shark"
  font = 'timesrb'

  library(ggplot2)
  string_df <- create_string_df(text = text, font = font)

  ggplot(string_df) +
    geom_path(aes(x, y, group = interaction(char_idx, stroke))) +
    coord_equal() +
    theme_minimal()


}
