# ==============================================================================
# mise en place
# ==============================================================================

# ------------------------------------------------------------------------------
# installer les packages nécessaires
# ------------------------------------------------------------------------------

# installer `{here}` si le package est absent
if (!base::require("here", quietly = TRUE)) {
  install.packages("here")
}
source(here::here("R", "01_installer_packages_requis.R"))

# ------------------------------------------------------------------------------
# définir les répertoires
# ------------------------------------------------------------------------------

source(here::here("R", "02_definir_repertoires.R"))

# ------------------------------------------------------------------------------
# charger les détails de connexion au serveur
# ------------------------------------------------------------------------------

source(here::here("_details_serveur.R"))
source(here::here("R", "03_valider_details_serveur.R"))

# ==============================================================================
# Données 💾
# ==============================================================================

# ------------------------------------------------------------------------------
# Purger les anciens fichiers
# ------------------------------------------------------------------------------

# téléchargées
susoflows::delete_in_dir(dir_donnees_telechargees)
# fusionnées
susoflows::delete_in_dir(dir_donnees_fusionnees)

# ------------------------------------------------------------------------------
# Télécharger les données en archive(s) zip
# ------------------------------------------------------------------------------

susoflows::download_matching(
  matches = nsu_qnr_expr,
  export_type = "STATA",
  path = dir_donnees_telechargees,
  server = serveur,
  workspace = espace_travail,
  user = utilisateur,
  password = mot_de_passe,
)

# ------------------------------------------------------------------------------
# Décomprimer archive(s) zip
# ------------------------------------------------------------------------------

susoflows::unzip_to_dir(dir_donnees_telechargees)

# ==============================================================================
# Images 📷
# ==============================================================================

# ------------------------------------------------------------------------------
# Purger les anciens fichiers
# ------------------------------------------------------------------------------

# téléchargées
susoflows::delete_in_dir(dir_images_telechargees)
# classées
susoflows::delete_in_dir(dir_images_classees)

# ------------------------------------------------------------------------------
# Télécharger images en archive(s) zip
# ------------------------------------------------------------------------------

susoflows::download_matching(
  matches = nsu_qnr_expr,
  export_type = "Binary",
  path = dir_images_telechargees,
  server = serveur,
  workspace = espace_travail,
  user = utilisateur,
  password = mot_de_passe,
)

# ------------------------------------------------------------------------------
# Décomprimer archive(s) zip
# ------------------------------------------------------------------------------

susoflows::unzip_to_dir(dir_images_telechargees)
