box::use(
  RSelenium[selKeys],
  tibble[tibble],
  rvest[...],
  stringr[str_extract],
  digest[digest],
  purrr[map_dfr, transpose,safely]
)


#' @export
facebook_login <- function(client, user, pass){
  client$navigate("https://touch.facebook.com/login")

  input_usuario <- client$findElement(using ="xpath", value = "//input[@id = 'm_login_email']")
  input_usuario$sendKeysToElement(list(user))

  input_clave <- client$findElement(using ="xpath", value = "//input[@id = 'm_login_password']")
  input_clave$sendKeysToElement(list(pass))

  input_clave$sendKeysToElement(list(selKeys$enter))

  Sys.sleep(3)
  boton_aceptar <- client$findElement(using ="xpath", value = "//button[@value = 'Aceptar']")
  boton_aceptar$clickElement()
  return(client)
}

#' @export
scroll <- function(navegador, tiempo_espera, tiempo_maximo) {
  hora_final <- Sys.time() + lubridate::seconds(tiempo_maximo)
  while (TRUE) {
    navegador$executeScript("window.scrollTo(0, document.body.scrollHeight);")
    Sys.sleep(tiempo_espera)
    if(Sys.time() > hora_final) break
  }
  return(invisible(navegador))
}
