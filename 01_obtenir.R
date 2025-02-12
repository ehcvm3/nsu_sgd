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
