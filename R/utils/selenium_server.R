# dependencias ------------------------------------------------------------

box::use(
  RSelenium[rsDriver],
  netstat[free_port]
)

#' @export
start_selenium <- function(headless = FALSE){
  if(headless){
    remote_driver <- rsDriver(
      browser = "firefox",
      chromever = NULL,
      verbose = TRUE,
      extraCapabilities = list(
        "moz:firefoxOptions" = list(
          args = list('--headless')
        )
      ),
      port = free_port()
    )
  }else {
    remote_driver <- rsDriver(
      browser = "firefox",
      chromever = NULL,
      verbose = TRUE,
      port = free_port()
    )
  }
  return(remote_driver)
}

