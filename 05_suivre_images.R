# ==============================================================================
# mise en place
# ==============================================================================

# ------------------------------------------------------------------------------
# confirmer que les outils de système sont présents
# ------------------------------------------------------------------------------

source(here::here("R", "01_confirmer_outils_systeme.R"))

# ------------------------------------------------------------------------------
# définir les répertoires
# ------------------------------------------------------------------------------

source(here::here("R", "02_definir_repertoires.R"))

# ------------------------------------------------------------------------------
# confirmer que les images classées sont présentes
# ------------------------------------------------------------------------------

chemins_images_classees <- fs::dir_ls(
  path = dir_images_classees,
  type = "file",
  regexp = "\\.jpg",
  recurse = TRUE
)

if (length(chemins_images_classees) == 0) {

  cli::cli_abort(
    message = c(
      "x" = "Aucune image classée retrouvée.",
      "i" = "Veuillez d'abord classer les images",
      "i" = "Pour ce faire, lancer {.file 03_classer_images.R}"
    )
  )

}

# ==============================================================================
# créer le rapport
# ==============================================================================

# construire le chemin du document
rapport_nom_fichier_sans_ext <-  "rapport_suivi_images"
chemin_rapport_sortie <- fs::path(
  dir_suivre, "rapport",
  paste0(rapport_nom_fichier_sans_ext, ".html")
)
chemin_rapport_modele <- fs::path(
  dir_suivre, "inst",
  paste0(rapport_nom_fichier_sans_ext, ".qmd")
)

# purger l'ancien document, s'il existe
tryCatch(
  error = function(cnd) {
    cat("Le rapport de suivi n'existe pas encore.")
  },
  fs::file_delete(chemin_rapport_sortie)
)

# créer le document in situ
quarto::quarto_render(input = chemin_rapport_modele)

# déplacer le document vers le dossier de sortie
fs::file_move(
  path = fs::path(
    dir_suivre_rapport_modele,
    paste0(rapport_nom_fichier_sans_ext, ".html")
  ),
  new_path = chemin_rapport_sortie
)
