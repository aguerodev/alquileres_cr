

get_bus_travel_time <- function(from_lat, from_lng, to_lat, to_lng){

  box::use(
    rvest[read_html_live, html_element, html_text],
    glue[glue]
  )

  url <- glue("https://moovitapp.com/san_jose-2967/poi/Parque%20Morazán%20%28Morazan%20Park%29/Ubicación%20elegida/es-419?tll={from_lat}_{from_lng}&fll={to_lat}_{to_lng}")
  cat(url)
  page <- read_html_live(url)
  Sys.sleep(3)
  duration <- page |>
    html_element(
      css = ".duration"
    ) |>
    html_text()

  return(duration)
}

get_bus_travel_time(
  from_lat = 9.866297,
  from_lng =  -83.917734,
  to_lat = 9.928836,
  to_lng = -84.042360
)

library(osrm)
origen <- data.frame(-83.917734,9.866297)
destino <- data.frame(-84.042360,9.928836)
duracion <- osrmTable(src = origen, dst =destino,
                      osrm.profile = "foot",
                      measure = c('duration', 'distance'))
duracion
