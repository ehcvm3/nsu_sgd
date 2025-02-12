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
# charger les fonctions utilitaires
# ------------------------------------------------------------------------------

source(fs::path(dir_fusionner, "R", "fct_fusionner.R"))
source(fs::path(dir_classer, "R", "fct_classer_images.R"))

# ==============================================================================
# faire l'inventiare des images téléchargées
# ==============================================================================

infos_images <- inventorier_images(dir = dir_images_telechargees)

infos_cle_images <- extraire_info_cle_images(df = infos_images)

# ==============================================================================
# créer les répertoires cible à partir des données reçues
# ==============================================================================

# ------------------------------------------------------------------------------
# extraire les étiquettes afin de former les chemins cible avec
# ------------------------------------------------------------------------------

# obtenir le chemin de la dernière version de l'appli
chemin_derniere_version <- obtenir_chemin_der_version(
  dir = dir_donnees_telechargees
)

# obtenir le chemin des données du questionnaire
chemins <- obtenir_chemins_qnr(dir = chemin_derniere_version)

# ingérer les données du questionnarie afin de les exploiter par la suite
nsu_qnr_df <- susometa::parse_questionnaire(path = chemin_qnr_json)

# produits
lbls_produits <- groupes |>
	purrr::map(
    .f = ~ susometa::get_answer_options(
      qnr_df = nsu_qnr_df,
      varname = !!rlang::sym(glue::glue("q100_{.x}"))
    )
  ) |>
  purrr::reduce(.f = c)

# unités
lbls_unites <- groupes |>
  purrr::map(
    .f = ~ susometa::get_answer_options(
      qnr_df = nsu_qnr_df,
      varname = !!rlang::sym(glue::glue("q101_{.x}"))
    )
  ) |>
  # reduce the list by combining elements into a single vector
  purrr::reduce(.f = c) |>
  # remove duplicated entries
  # composing and then invokign an anonymous function
  (\(x) x[!duplicated(x)])() |>
  sort()

# ------------------------------------------------------------------------------
# créer des chemins cibles relatifs à partir des données des unités retrouvées
# ------------------------------------------------------------------------------

# # créer l'expression régulière qui identifie les groupes de produits dans
# # les noms de fichiers et de colonnes
# regexpr_groupes <- creer_regexpr_groupe(groupes = groupes)

df_chemins_cible <- composer_chemins_cible(
  chemin_unites = fs::path(dir_donnees_fusionnees, "unites_retrouvees.dta"),
  lbls_produits = lbls_produits,
  lbls_unites = lbls_unites
)

# ------------------------------------------------------------------------------
# créer une base des chemins source (i.e. lieu de téléchargé) et
# chemins cible (i.e., lieu de reclassement)
# ------------------------------------------------------------------------------

df_chemins_source_cible <- creer_chemins_source_et_cible(
  df_chemins_source = infos_cle_images,
  df_chemins_cible =  df_chemins_cible
)

# ==============================================================================
# créer les répertoires cible
# ==============================================================================

fs::dir_create(
  path = fs::path(dir_images_classees, df_chemins_cible$repertoire_cible),
  recurse = TRUE
)

# ==============================================================================
# copier les images depuis le chemin source vers le chemin cible
# ==============================================================================

fs::file_copy(
  path = df_chemins_source_cible$chemin_source,
  new_path = df_chemins_source_cible$chemin_cible,
  overwrite = TRUE
)
