# ==============================================================================
# fusionner les bases et harmoniser les noms de variable
# ==============================================================================

# ------------------------------------------------------------------------------
# préparer les entrées auxiliaires
# ------------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# faire une liste des répertoires de versions de l'appli CAPI
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

chemins_versions <- fs::dir_ls(
  path = dir_donnees_telechargees,
  type = "directory",
  recurse = FALSE
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# préparer l'expression régulière pour identifier les groupes de produits dans
# le nom des bases et de variable
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

groupes <- c(
  "cereales", "viandes", "poissons", "laitier", "huiles",
  "fruits", "legumes", "leg_tub", "sucreries", "epices", "boissons"
)
regexpr_prods <- creer_regexpr_groupe(groupes = groupes)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# extraire les étiquettes de valeur pour les produits et unités, et tailles
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

# obtenir le chemin de la dernière version de l'appli
chemin_derniere_version <- obtenir_chemin_der_version(
  dir = dir_donnees_telechargees
)

# obtenir le chemin des données du questionnaire
chemins <- obtenir_chemins_qnr(dir = chemin_derniere_version)

# ingérer les données du questionnarie afin de les exploiter par la suite
nsu_qnr_df <- susometa::parse_questionnaire(path = chemins$chemin_qnr_json)

# par précaution, écraser une base c afin d'éviter une référence ambigue
suppressWarnings(rm(c))

# produits
lbls_produits <- groupes |>
  purrr::map(
    .f = ~ susometa::get_answer_options(
      qnr_df = nsu_qnr_df,
      varname = !!rlang::sym(glue::glue("q100_{.x}"))
    )
  ) |>
  purrr::reduce(.f = c)

# unites lbls_unites <- groupes |>
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

# tailles
# extraire l'identifiant de catégories réutilisables de la base JSON
tailles_categories_id <- nsu_qnr_df |>
	dplyr::filter(varname == "q103_cereales") |>
	dplyr::pull(categories_id) |>
  stringr::str_replace_all(
    pattern = "-",
    replacement = ""
  )

# ingérer les catégories et ne retenir que les catégories réutilsables de taille
tailles_categories_df <- chemins$dir_categories |>
	susometa::parse_categories() |>
  dplyr::filter(categories_id == tailles_categories_id)

# construire un vecteur numérique libellé
lbls_tailles <- stats::setNames(
  object = tailles_categories_df$value,
  nm = tailles_categories_df$text
)

# ------------------------------------------------------------------------------
# marché
# ------------------------------------------------------------------------------

# préparer
marches <- fusionner_marche(dir_parent = dir_donnees_telechargees)

# sauvegarder
haven::write_dta(
  data = marches,
  path = fs::path(dir_donnees_fusionnees, "marches.dta")
)

# ------------------------------------------------------------------------------
# produits
# ------------------------------------------------------------------------------

# préparer
produits_df <- chemins_versions |>
  # fusionner les données de chaque répertoire
	purrr::map(
    .f = ~ fusionner_produits(
      dir = .x,
      regexpr = regexpr_prods
    )
  ) |>
  # concaténer les bases harmonisées issues de chaque répertoire
	dplyr::bind_rows()
	
# sauvegarder
haven::write_dta(
  data = produits_df,
  path = fs::path(dir_donnees_fusionnees, "produits.dta")
)

# ------------------------------------------------------------------------------
# unités absentes
# ------------------------------------------------------------------------------

# préparer
unites_absentes_df <- chemins_versions |>
  # fusionner les données de chaque répertoire
	purrr::map(
    .f = ~ fusionner_unites_absentes(
      dir = .x,
      regexpr = regexpr_prods
    )
  ) |>
  # concaténer les bases harmonisées issues de chaque répertoire
	dplyr::bind_rows() |>
	# libeller les identifiants, parfois dépourvus d'étiquettes de valeur
  labelled::set_value_labels(
    produits__id = lbls_produits,
    unites_absentes__id = lbls_unites
  )

# sauvegarder
haven::write_dta(
  data = unites_absentes_df,
  path = fs::path(dir_donnees_fusionnees, "unites_absentes.dta")
)

# ------------------------------------------------------------------------------
# unités retrouvées
# ------------------------------------------------------------------------------

# préparer
unites_retrouvees_df <- chemins_versions |>
  # fusionner les données de chaque répertoire
	purrr::map(
    .f = ~ fusionner_unites_retrouvees(
      dir = .x,
      regexpr = regexpr_prods
    )
  ) |>
	dplyr::bind_rows() |>
	# libeller les identifiants, parfois dépourvus d'étiquettes de valeur
  labelled::set_value_labels(
    produits__id = lbls_produits,
    unites__id = lbls_unites
  )

# sauvegarder
haven::write_dta(
  data = unites_retrouvees_df,
  path = fs::path(dir_donnees_fusionnees, "unites_retrouvees.dta")
)

# ------------------------------------------------------------------------------
# tailles
# ------------------------------------------------------------------------------

# fusionner
tailles_df <- chemins_versions |>
	purrr::map(
    .f = ~ fusionner_releves(
      dir = .x,
      regexpr = regexpr_prods
    )
  ) |>
	dplyr::bind_rows() |>
	# libeller les identifiants dépourvus d'étiquettes de valeur
  labelled::set_value_labels(
    produits__id = lbls_produits,
    unites__id = lbls_unites,
    tailles__id = lbls_tailles
  )

# sauvegarder
haven::write_dta(
  data = tailles_df,
  path = fs::path(dir_donnees_fusionnees, "tailles.dta")
)
