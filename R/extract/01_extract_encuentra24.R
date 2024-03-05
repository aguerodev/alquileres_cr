library(tidyverse)
library(jsonlite)
library(sf)
library(glue)
library(janitor)
library(furrr)
source("R/utils/api_openai.R")
library("future.callr")
plan(callr)


gam <- c(
  "San José",
  "Escazú",
  "Desamparados",
  "Aserrí",
  "Mora",
  "Goicoechea",
  "Santa Ana",
  "Alajuelita",
  "Vázquez De Coronado",
  "Tibás",
  "Moravia",
  "Montes de Oca",
  "Curridabat",
  "Alajuela",
  "Atenas",
  "Poás",
  "Cartago",
  "Paraíso",
  "La Unión",
  "Oreamuno",
  "Alvarado",
  "El Guarco",
  "Heredia",
  "Barva",
  "Santo Domingo",
  "Santa Bárbara",
  "San Rafael",
  "San Isidro",
  "Belén",
  "Flores",
  "San Pablo"
)
cantones <- read_rds("data/sf_cantones_cr.rds")
cantones <- sf::st_set_crs(cantones, "EPSG:4326")

cantones <- cantones |>
  filter(canton %in% gam)

bbox <- st_bbox(cantones)
x <- st_make_grid(cantones, cellsize = 0.03)
x <- x[cantones]
x

centers <- as_tibble(st_coordinates(x)) |>
  rename(
    lat = Y,
    lng = X
  ) |>
  mutate(
    ulat = lat - 0.08184425,
    llat = lat + 0.08184425,
    ulng = lng - 0.08136749,
    llng = lng + 0.08136749
  )

result <- map(transpose(centers), \(x){
  url <- glue("https://www.encuentra24.com/costa-rica-es/bienes-raices-alquiler-apartamentos/map/data?q=lat.{x$lat}|lng.{x$lng}|zoom.12|withcat.bienes-raices-alquiler-apartamentos,bienes-raices-alquiler-casas,bienes-raices-alquiler-apartamentos-amueblados&regionslug=san-jose-provincia,alajuela-provincia,cartago-provincia,heredia-provincia&page=1&list=categorymap&ulat={x$ulat}&ulng={x$ulng}&llat={x$llat}&llng={x$llng}")
  x <- fromJSON(url)
  x$data$data |>
    as_tibble()
},.progress = TRUE)

result2 <- list_rbind(result) |>
  filter(!duplicated(lid))

extract_desc <- \(x){
  url <- paste0("https://www.encuentra24.com", x)
  read_html(url) |>
    html_elements(
      xpath = "//section[@class = 'product-box']/descendant-or-self::*/text()"
    ) |>
    html_text2() |>
    paste0(collapse = "")
}
extract_desc <- possibly(extract_desc, otherwise = NULL)
desc <- future_map_chr(result2$lin, extract_desc , .progress = TRUE)

result2$des2 <- desc

# descargar fotos de los apartamentos

write_rds(result2, "data-raw/encuentra_24/encuentra_24v2.rds")

.prompt <- read_lines("R/utils/details_prompt.txt") |>
  paste0(collapse = " ")

info <- future_map(transpose(result2[1:5,]), \(x){
  y <- gpt4_turbo(
    .prompt = .prompt,
    input = x$des2
  )
  df <- fromJSON(y) |>
    as_tibble() |>
    clean_names()
  df$id <- x$lid
  return(df)
}, .progress = TRUE) |>
  list_rbind()


walk(transpose(result2), \(x){
  url <- paste0("https://www.encuentra24.com",x$lin)
  id <- x$lid


  imgs <- read_html(url) |>
    html_elements(
      xpath = "//*[@data-lightbox = 'product-gallery']/img"
    ) |>
    html_attr("data-lazy") |>
    head(3)

  walk(seq_along(imgs), \(i){
    .destfile <- glue("data-raw/encuentra_24/imgs/{id}_{i}.jpeg")
    download.file(
      url = imgs[i],
      destfile = .destfile,
      quiet = TRUE
    )
  })
},.progress = TRUE)

