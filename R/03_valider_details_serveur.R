# ==============================================================================
# Server connection details
# ==============================================================================

# ------------------------------------------------------------------------------
# Connection details provided
# ------------------------------------------------------------------------------

missing_server_params <- c(
  serveur, espace_travail, utilisateur, mot_de_passe
) == ""

if (any(missing_server_params)) {

  connection_params <- c(
    "serveur", "espace_travail", "utilisateur", "mot_de_passe"
  )

  missing_server_params_txt <- connection_params[missing_server_params]

  stop(
    glue::glue(
      "Détails de connexion au serveur absent.",
      paste0(
        "Les détails suivants ont été laissé vides dans _details_server.R :",
        glue::glue_collapse(
          glue::backtick(missing_server_params_txt),
          last = ", et "
        )
      ),
      .sep = "\n"
    )
  )

}

# ------------------------------------------------------------------------------
# Server exists at specified URL
# ------------------------------------------------------------------------------

server_exists <- function(url) {

  tryCatch(
    expr = httr::status_code(httr::GET(url = url)) == 200,
    error = function(e) {
      FALSE
    }
  )

}

if (!server_exists(url = serveur)) {
  stop(paste0("Le serveur n'existe pas à l'adresse fournie : ", serveur))
}

# ------------------------------------------------------------------------------
# Credentials valid
# ------------------------------------------------------------------------------

credentials_valid <- suppressMessages(
	susoapi::check_credentials(
    server = serveur,
    workspace = espace_travail,
    user = utilisateur,
    password = mot_de_passe,
		verbose = TRUE
	)
)

if (credentials_valid == FALSE) {

  stop(
    glue::glue(
      "Informations d'identification non valides pour l'utilisateur API.",
      "L'un des problèmes suivants peut être présent.",
      paste0(
        "1. Ces informations d'identification peuvent être invalide",
        "(e.g., mauvais utilistaeur, mot de passe, etc)."
      ),
      paste0(
        "2. Ces informations peuvent être pour le mauvais type d'utilisateur",
        "(e.g., Headquarters)."
      ),
      "3. L'utilisateur peut ne pas avoir accès à l'espace de travail cible.",
      "Veuillez vérifier et reprendre.",
      .sep = "\n"
    )
  )

}

# ------------------------------------------------------------------------------
# Confirmer que le(s) questionnaire(s) cible existe(nt)
# ------------------------------------------------------------------------------

tryCatch(
  expr = susoflows::find_matching_qnrs(
    matches = nsu_qnr_expr,
    server = serveur,
    workspace = espace_travail,
    user = utilisateur,
    password = mot_de_passe
  ),
  warning = function(cnd) {

    qnrs <- susoapi::get_questionnaires(
      server = serveur,
      workspace = espace_travail,
      user = utilisateur,
      password = mot_de_passe
    ) |>
    dplyr::mutate(qnr_title = glue::glue("{title} (version {version})")) |>
    dplyr::pull(qnr_title) |>
    glue::glue_collapse(sep = ", ")

    cli::cli_abort(
      message = c(
        "x" = "Aucun questionnaire correspondant retrouvé",
        "i" = "Veuillez reprendre la valeur de {.code nsu_qnr_expr}",
        "i" = "Voici les questionnaires dans l'espace de travail cible : {qnrs}"
      ),
      call = rlang::caller_env()
    )

  }

)
