


suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(ggplot2)
})


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Read in all hershey font as data.frame
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
jhf_filenames <- list.files(here::here("data-raw/hershey"), pattern = '*.jhf', full.names = TRUE)
hershey <- jhf_filenames %>%
  map(convert_hershey_font_to_df) %>%
  bind_rows() %>%
  as.tbl() %>%
  mutate(stroke = as.factor(stroke))


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Join in ascii mapping
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ascii <- data.frame(
  ascii = 32:126,
  char  = strsplit(intToUtf8(32:126), '')[[1]],
  stringsAsFactors = FALSE
) %>%
  mutate(glyph = seq(n()))

hershey <- hershey %>% left_join(ascii, by = 'glyph')



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# But then there are a lot of fonts that we don't want ascii mapping
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ii <- hershey$font %in% c('markers', 'japanese', 'japanese2', 'symbolic')
hershey$char [ii] <- ''
hershey$ascii[ii] <- -1L



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# NA out individual glyphs in individual fonts
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
good <- c(1, 3, 9, 10, 13, 15, 17:26, 34:59, 66:91)
ii <- hershey$font == 'astrology' & !hershey$glyph %in% good
hershey$char [ii] <- ''
hershey$ascii[ii] <- -1L


good <- c(1, 6, 9, 10, 12:26, 29:31, 34:62, 92, 94)
ii <- hershey$font %in% c('mathlow', 'mathupp') & !hershey$glyph %in% good
hershey$char [ii] <- ''
hershey$ascii[ii] <- -1L


good <- c(1, 6, 9, 10, 11, 13:26, 32:62, 66:92, 94)
ii <- hershey$font == 'meterology' & !hershey$glyph %in% good
hershey$char [ii] <- ''
hershey$ascii[ii] <- -1L


good <- c(1, 2, 17:27, 34:62, 64:95)
ii <- hershey$font == 'music' & !hershey$glyph %in% good
hershey$char [ii] <- ''
hershey$ascii[ii] <- -1L





#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Replace NAs with zero-width blank as it looks nicer :)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hershey <- hershey %>%
  tidyr::replace_na(list(char = '', ascii = -1L))


usethis::use_data(hershey, overwrite = TRUE)




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Read in hershey fonts as glyph encodings
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hershey_raw <- jhf_filenames %>%
  map(read_jhf) %>%
  set_names(tools::file_path_sans_ext(basename(jhf_filenames)))


usethis::use_data(hershey_raw, overwrite = TRUE)



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Convert glyphs to SVG
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
convert_stroke_to_path <- function(stroke_df) {
  pairs      <- paste(stroke_df$x, -stroke_df$y)
  line_to    <- paste0('L', pairs)
  line_to[1] <- sub('L', 'M', line_to[1])
  path       <- paste(line_to, collapse = " ")
  path
}


convert_glyph_to_path <- function(glyph_df) {
  strokes       <- split(glyph_df, as.integer(glyph_df$stroke))
  path_segments <- vapply(strokes, convert_stroke_to_path, character(1))
  path          <- paste(path_segments, collapse = "")
  path <- gsub(" L", "L", path)
  path <- gsub(" -", "-", path)
  path
}

convert_font_to_paths <- function(font_df) {
  glyphs <- split(font_df, font_df$glyph)
  vapply(glyphs, convert_glyph_to_path, character(1))
}



hershey_svg <- split(hershey, hershey$font) %>%
  map(convert_font_to_paths)



usethis::use_data(hershey_svg, overwrite = TRUE)

if (FALSE) {
  svg <- glue::glue('<svg width="200" height="300" viewBox="-10 -10 20 20" xmlns="http://www.w3.org/2000/svg">
  <path d="{hershey_svg$cursive[[36]]}" stroke="black" fill="transparent" stroke-width="0.5">
             <animateTransform attributeName="transform"
                          attributeType="XML"
                          type="rotate"
                          from="0"
                          to="360"
                          dur="10s"
                          repeatCount="indefinite"/>
  </path>
</svg>')
  writeLines(svg, "test.svg")
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create the pdf for the given a data.frame with a single font
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
create_font_pdf <- function(font_df) {

  stopifnot(length(unique(font_df$font)) == 1L)
  font_name <- font_df$font[1]

  font_df <- font_df %>% mutate(
    label = sprintf("%03i %s", glyph, char)
  )

  p <- ggplot(font_df) +
    geom_path(aes(x, y, group=stroke)) +
    theme_void() +
    coord_equal() +
    theme(legend.position = 'none') +
    facet_wrap(~label) +
    labs(title = font_name)

  pdf_name <- paste0(font_name, ".pdf")
  pdf_name <- here::here("man", "figures", "font", pdf_name)

  ggsave(pdf_name, plot = p, width = 15, height = 15)
}



if (FALSE) {
  font_df <- hershey %>% filter(font == 'astrology')
  create_font_pdf(font_df)
} else {
  hershey %>%
    group_split(font) %>%
    walk(create_font_pdf)
}

