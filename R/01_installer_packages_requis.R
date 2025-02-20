# ------------------------------------------------------------------------------
# définir un programmes de travail pour l'identification et l'installation de
# programmes absents
# ------------------------------------------------------------------------------

#' Install package if missing on system
#' 
#' @param package Character. Name of package to install.
#'
#' @importFrom stringr str_detect str_locate str_sub
installer_si_absent <- function(package) {

  # if package contains a slash for GitHub repo, strip out the package name
  # and install that package
  slash_pattern <- "\\/"
  if (stringr::str_detect(string = package, pattern = slash_pattern)) {

    package_url <- package

    slash_position <- stringr::str_locate(
      string = package,
      pattern = slash_pattern
    )
    package <- stringr::str_sub(
      string = package,
      start = slash_position[[1]] + 1
    )

    if (!require(package, quietly = TRUE, character.only = TRUE)) {
      pak::pak(package_url)
    }

  # otherwises, install the package
  } else {

    if (!require(package, quietly = TRUE, character.only = TRUE)) {
      pak::pak(package)
    }

  }

}

# ------------------------------------------------------------------------------
# confirmer que RTools est installé
# ------------------------------------------------------------------------------

# installer `{here}` si le package est absent
if (!base::require("pkgbuild", quietly = TRUE)) {
  install.packages("pkgbuild")
}
# installer {cli} si le package est absent
if (!base::require("cli", quietly = TRUE)) {
  install.packages("cli")
}

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

}


# ------------------------------------------------------------------------------
# installer des packages pour faciliter l'installation
# ------------------------------------------------------------------------------

# itération et manipulation des listes
if (!base::require("purrr", quietly = TRUE)) {
  install.packages("purrr")
}
# manipulation des données string
if (!base::require("stringr", quietly = TRUE)) {
  install.packages("stringr")
}
# méthode d'installation de packages plus rapide, fiable, et moderne
if (!base::require("pak", quietly = TRUE)) {
  install.packages("pak")
}

# ------------------------------------------------------------------------------
# identifier les dépendences
# ------------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# par programme
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

pour_01_obtenir <- c(
  "arthur-shaw/susoflows" # flux de travail pour les données de SuSo
)

pour_fct_fusionner <- c(
  "glue", # interpolation de texte
  "dplyr", # manipulation des données
  "fs", # opérations le système des fichiers
  "haven", # ingérer/sauvegarder des fichiers Stata
  "arthur-shaw/susoflows" # décomprimer les fichers zip vers un répertoire
)

pour_02_fusionner_donnees <- c(
  "fs", # opérations le système des fichiers
  "lsms-worldbank/susometa", # extraires des infos de la métadonnée du qnr
  "rlang", # métaprogrammation
  "dplyr", # manipulation des données
  "haven", # ingérer/sauvegarder des fichiers Stata
  "labelled" # manipulation/application des étiquettes de variable et de valeur
)

pour_05_suivre <- c(
  "quarto", # vérifier l'installation de Quarto et créer de documents avec
  "cli", # afficher des message d'erreurs lisibles
  "fs", # opérations le système des fichiers
  "labelled", # manipulation/application des étiquettes de variable et de valeur
  "tibble", # créer des data frames avec certains attribus
  "dplyr", # manipulation des données
  "reactable", # créer des tableaux interactifs
  "readr", # ingérer les données du tableau de référence
  "haven", # ingérer/sauvegarder des fichiers Stata
  "htmltools" # créer un div pour chaque tableau imbriqué
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# globalement
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

packages_requis <- c(
  # 01 - obtenir
  pour_01_obtenir,
  # 02 - fusionner
  pour_fct_fusionner,
  pour_02_fusionner_donnees,
  # 05 - suivre
  pour_05_suivre
) |>
unique()

# ------------------------------------------------------------------------------
# installer les programmes absents
# ------------------------------------------------------------------------------

purrr::walk(
  .x = packages_requis,
  .f = ~ installer_si_absent(.x)
)
