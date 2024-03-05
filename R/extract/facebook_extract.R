library(tidyverse)
library(digest)

source("R/utils/selenium_server.R")
source("R/utils/login_facebook.R")

.config <- config::get()
server <- start_selenium()
client <- server$client

client |>
  facebook_login(
    user = .config$facebook_username,
    pass = .config$facebook_password
  )

client$navigate("https://www.facebook.com/marketplace/sanjosecr/propertyrentals/?exact=true")
scroll(client,tiempo_espera = 3, tiempo_maximo = 60*5)

apartamentos <- client$findElements(
  using = "xpath",
  value = "//div[@class = 'x3ct3a4']/a"
)

urls <- map_vec(apartamentos, \(x) x$getElementAttribute("href")[[1]])

extract_posts <- function(url){
  client$navigate(url)

  x <- client$findElement(
    using = "xpath",
    value = "//div[@class = 'xyamay9 x1pi30zi x18d9i69 x1swvt13']"
  )

  df <- x$getElementText() |>
    str_split("\n") |>
    unlist() |>
    set_names(c("titulo","precio","categoria")) |>
    t() |>
    as_tibble()

  x <- client$findElement(
    using = "xpath",
    value = "//div[contains(@style, 'static_map.php')]"
  )
  df$cordenadas <- x$getElementAttribute("style")[[1]]

  tryCatch(expr = {
    btn <- client$findElement(
      using = "xpath",
      value = "//span[contains(text(), 'Ver más')]"
    )
    btn$clickElement()
  },
  error = function(x) NULL
  )

  x <- client$findElement(
    using = "xpath",
    value = "//div[@class = 'xz9dl7a x4uap5 xsag5q8 xkhd6sd x126k92a']"
  )
  df$descripcion <- x$getElementText()[[1]]

  x <- client$findElements(
    using = "xpath",
    value =   "//img[@class = 'x5yr21d xl1xv1r xh8yej3']"
  )
  df$fotos <- map_vec(x, \(x) x$getElementAttribute("src")[[1]]) |>
    paste(collapse = ",")

  id <- digest(url, algo="md5", serialize=F)
  df$url <- url
  df$df <- id

  write_rds(x = df, file = paste0("data-raw/facebook_marketplace/",id,".rds"))
  return(df)
}
extract_posts <- possibly(extract_posts, otherwise = NULL)
extract_posts <- slowly(extract_posts, rate = rate_delay(pause = 3))

posts <- map(urls, extract_posts, .progress = TRUE)
posts <- list_rbind(posts)
write_rds(posts, file = "data-raw/facebook_marketplace/todos.rds")
