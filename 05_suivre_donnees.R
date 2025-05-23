# ==============================================================================
# mise en place
# ==============================================================================

# ------------------------------------------------------------------------------
# activer l'environnement du projet
# ------------------------------------------------------------------------------

renv::restore(prompt = FALSE)

# ------------------------------------------------------------------------------
# charger les définitions et paramètres
# ------------------------------------------------------------------------------

# répertoires
source(here::here("R", "02_definir_repertoires.R"))
# détails de connexion au serveur
source(here::here("_details_serveur.R"))

# ------------------------------------------------------------------------------
# confirmer que les données fusionnées sont présentes
# ------------------------------------------------------------------------------

chemins_bases_fusionnees <- fs::dir_ls(
  path = dir_donnees_fusionnees,
  type = "file",
  regexp = "\\.dta"
)

if (length(chemins_bases_fusionnees) == 0) {

  cli::cli_abort(
    message = c(
      "x" = "Aucun fichier de données fusionnées retrouvé.",
      "i" = "Veuillez d'abord fusionner les données",
      "i" = "Pour ce faire, lancer {.file 02_fusionner_donnees.R}"
    )
  )

}

# ==============================================================================
# créer le rapport
# ==============================================================================

# construire le chemin du document
rapport_nom_fichier_sans_ext <-  "rapport_suivi_nsu"
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

# purger les anciennes données
donnees_a_supprimer <- fs::dir_ls(
  path = dir_suivre_donnees,
  type = "file",
  regexp = "\\.dta"
)
fs::file_delete(donnees_a_supprimer)

# créer le document in situ
quarto::quarto_render(
  input = chemin_rapport_modele,
  execute_params = list(
    serveur = serveur,
    espace_travail = espace_travail
  )
)

# déplacer le document vers le dossier de sortie
fs::file_move(
  path = fs::path(
    dir_suivre_rapport_modele,
    paste0(rapport_nom_fichier_sans_ext, ".html")
  ),
  new_path = chemin_rapport_sortie
)
