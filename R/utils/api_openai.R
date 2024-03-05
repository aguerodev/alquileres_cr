box::use(
  httr2[...]
)

#' @export
.config <- config::get()
gpt4_turbo <- function(.prompt = NA,
                       input = NA,
                       openai_api_key = .config$openai_api_key) {


  # Crear un objeto de solicitud
  req <- request("https://api.openai.com/v1/chat/completions") |>
    req_headers(
      `Content-Type` = "application/json",
      `Authorization` = paste("Bearer", openai_api_key)
    ) |>
    req_body_json(
      list(
        model = "gpt-4",
        messages = list(
          list(role = "system", content = .prompt),
          list(role = "user", content = input)
        ),
        temperature = 1,
        max_tokens = 500,
        top_p = 1,
        frequency_penalty = 0,
        presence_penalty = 0
      )
    )

  # Enviar la solicitud y obtener la respuesta
  respuesta <- req |> req_perform()

  # Procesar la respuesta
  contenido <- respuesta |> resp_body_json()
  contenido <- contenido$choices[[1]]$message$content

  return(contenido)
}



