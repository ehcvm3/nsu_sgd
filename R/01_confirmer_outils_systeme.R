# ------------------------------------------------------------------------------
# confirmer que RTools est installé
# ------------------------------------------------------------------------------

if (pkgbuild::has_build_tools() == FALSE) {

  url_rtools <- "https://github.com/ehcvm3/creer_tableau_produit_unite_taille?tab=readme-ov-file#rtools"

  cli::cli_abort(
    message = c(
      "x" = "RTools est introuvable. Veuillez l'installer.",
      "i" = "Sur Windows, R a besoin d'un outil pour compiler le code source.",
      "i" = paste0(
        "Veuillez suivre les instructions ici pour installer RTools : ",
        "{.url {url_rtools}}"
      )
    )
  )

} else {
  cli::cli_inform(
    message = c(
      "v" = "RTools retrouvé"
    )
  )
}

# ------------------------------------------------------------------------------
# confirmer que Quarto est installé
# ------------------------------------------------------------------------------

if (is.null(quarto::quarto_path())) {

  url_quarto <- "https://quarto.org/docs/get-started/"

  cli::cli_abort(
    message = c(
      "x" = "Quarto est introuvable. Veuillez l'installer.",
      "i" = "Pour créer une sortie, le programme a besoin de Quarto.",
      "i" = "Pour l'installer, suivre les instructions ici : ",
      "{.url {url_quarto}}"
    )
  )

} else {
  cli::cli_inform(
    message = c(
      "v" = "Quarto retrouvé"
    )
  )
}