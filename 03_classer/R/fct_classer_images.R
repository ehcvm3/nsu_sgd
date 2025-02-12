#' Faire l'inventaire des images
#'
#' @description
#' Le réperotire des images peut comporter plusieurs
#'
#' @param dir Caractère. Chemin du répertoire où les images ont été
#' téléchargées et décomprimées. Ce répertoire devrait contenir un
#' sous-répertoire par version de l'appli CAPI.
#'
#' @return Data frame. Sortie habituelle de `fs::file_info()` plus une
#' colonne indiquant le chemin du répertoire mère--c'est à dire le chemin
#' du répertoire qui contient les données d'une version.
#'
#' @importFrom fs dir_ls dir_info
#' @importFrom purrr map
inventorier_images <- function(dir) {

  # confirmer que le répertoire existe
  if (!fs::dir_exists(dir)) {

    cli::cli_abort(
      message = c(
        "x" = "Dossier n'existe pas, ou le chemin n'est pas un dossier.",
        "i" = "Chemin du dossier : {.path {dir}}"
      )
    )

  }

  # faire une liste des répertoires de versions
  dirs_version <- fs::dir_ls(
    path = dir,
    type = "directory"
  )

  # confirmer que des sous-répertoires existent
  if (length(dirs_version) == 0) {

    cli::cli_abort(
      message = c(
        "x" = "Aucun sous-dossier retrouvé dans le dossier indiqué.",
        "i" = "Chemin du dossier : {.path {dir}}"
      )
    )

  }

  # obtenir des infos sur les images
  info_fichiers <- dirs_version |>
    purrr::map(
      .f = ~ fs::dir_info(
        path = .x,
        type = "file",
        recurse = TRUE
      )
    ) |>
    # ajouter le chemin du répertoire mère pour la version de l'appli CAPI
    dplyr::bind_rows(.id = "chemin_mere")

  return(info_fichiers)

}

#' Extaire les infos clé des infos sur les images
#'
#' @description
#' Le chemin des images contient des informations nécessaires pour comprendre
#' leur contenu et les classer correctement. Cette fonction extrait ces infos
#' dans des colonnes d'une base de données.
#'
#' @param df Data frame. Sortie de `inventorier_images()`
#'
#' @return Data frame. Les colonnes incluent:
#' - interview__key
#' - Nom du fichier
#' - Code du produit
#' - Code d'unité
#'
#' @importFrom dplyr mutate if_else across select
#' @importFrom purrr map2_chr
#' @importFrom fs path_rel path_dir path_file
#' @importFrom stringr str_extract str_detect
extraire_info_cle_images <- function(df) {

  df_infos_cle <- df |>
    dplyr::mutate(
      # extraire l'identifiant d'entretien du chemin
      interview__key = purrr::map2_chr(
        .x = path,
        .y =  chemin_mere,
        .f = ~ fs::path_rel(
          path = fs::path_dir(.x),
          start = .y
        )
      ),
      # extraire le nom du fichier du chemin
      nom_fichier = fs::path_file(path),
      # extraire les codes de produit et d'unité du nom de fichier
      code_produit = stringr::str_extract(
        string = nom_fichier,
        pattern = "(?<=__)[0-9]{1,3}(?=-)"
      ),
      code_unite = dplyr::if_else(
        condition = stringr::str_detect(
          string = nom_fichier,
          pattern = "--[0-9]{2}"
        ),
        true = stringr::str_extract(
          string = nom_fichier,
          pattern = "(?=-)-[0-9]{2}(?=.jpg)"
        ),
        false = stringr::str_extract(
          string = nom_fichier,
          pattern = "(?<=-)[0-9]{1,3}(?=.jpg)"
        )
      ),
      # convertir de type caractère à type numérique
      dplyr::across(
        .cols = c(code_produit, code_unite),
        .fns = ~ as.numeric(.x)
      )
    ) |>
    dplyr::select(
      chemin_source = path, change_time, birth_time,
      interview__key, nom_fichier, code_produit, code_unite
    )

  return(df_infos_cle)

}

#' Composer les chemins cibles où classer les images
#'
#' @description
#' 
#' @param chemin_unites Caractère. Chemin des de la base des unités retrouvées
#' fusionnée.
#' @param lbls_produits Vecteur caractère nommé. Contient les étiquettes de
#' valeur des produits.
#' @param lbls_unites Vecteur caractère nommé. Contient les étiquettes de
#' valeur des unités.
#'
#' @return Data frame. Contient le chemin cible relatif à créer au sein du
#' répertoire des images classées.
#'
#' @importFrom dplyr distinct across
#' @importFrom labelled set_value_laels to_character
#' @importFrom haven zap_labels
#' @importFrom glue glue
composer_chemins_cible <- function(
  chemin_unites,
  lbls_produits,
  lbls_unites
) {

  repertoires_a_creer <- chemin_unites |>
    # ingérer la base fusionnée
    haven::read_dta() |>
    # ne retenir que les combinaisons distinctes de produit et d'unité
    dplyr::distinct(produits__id, unites__id) |>
    # appliquer les étiquettes de valeur extraites du questionnaire JSON
    labelled::set_value_labels(
      produits__id = lbls_produits,
      unites__id = lbls_unites
    ) |>
    # créer les codes et les noms afin de composer le chemin cible
    dplyr::mutate(
      code_produit = haven::zap_labels(produits__id),
      nom_produit = labelled::to_character(produits__id, levels = "labels"),
      code_unite = haven::zap_labels(unites__id),
      nom_unite = labelled::to_character(unites__id),
      # purger les caractères interdits dans les chemins chez Windows/Unix
      dplyr::across(
        .cols = c(nom_produit, nom_unite),
        .fns = ~ purger_mauvais_char_chemin(var = .x)
      ),
      # raccourcir le chemin en enlevant les exemples entre parenthèses
      dplyr::across(
        .cols = c(nom_produit, nom_unite),
        .fns = ~ raccourcir_chemin(var = .x)
      ),
      # composer les chemins cible avec le code et le nom
      # des produits et des unités, respectivement
      repertoire_cible = glue::glue(
        "{code_produit}_{nom_produit}/{code_unite}_{nom_unite}"
      )
    )

  return(repertoires_a_creer)

}

creer_chemins_source_et_cible <- function(
  df_chemins_source,
  df_chemins_cible
) {

  df_source_cible <- df_chemins_source |>
    # ajouter les répertoire de cible
    dplyr::left_join(
      y = df_chemins_cible,
      by = c("code_produit", "code_unite")
    ) |>
    dplyr::mutate(
      # ajouter la clé de l'entretien au nom de l'image afin de donner sa source
      nom_fichier_sans_ext = fs::path_ext_remove(nom_fichier),
      ext = fs::path_ext(nom_fichier),
      nom_fichier_avec_key = glue::glue(
        "{nom_fichier_sans_ext}_{interview__key}.{ext}"
      ),
      # construire le chemin cible
      chemin_cible = fs::path(
        dir_images_classees, # racine
        repertoire_cible, # sous-répertoires produit-unité
        nom_fichier_avec_key # nouveau nom de fichier image
      )
    ) |>
    dplyr::select(chemin_source, chemin_cible)

  return(df_source_cible)

}

#' Purger les caractères interdits dans les chemins chez Windows/Unix
#'
#' @description
#' Voir ici: https://stackoverflow.com/questions/1976007/what-characters-are-forbidden-in-windows-and-linux-directory-names
#'
#' @param var Bare name. Nom de la variable cible.
#'
#' @return Character. Texte modifié
#'
#' @importFrom stringr str_replace_all str_trim
purger_mauvais_char_chemin <- function(var) {

  chemin_col <- 
    # purger les caractères interdits dans les chemin chez Windows/Unix
    stringr::str_replace_all(
      string = {{var}},
      pattern = '(<|>|:|/|\\\\|\\|)',
      replacement = "-"
    ) |>
    # remove quotes nearly forbidden characters
    stringr::str_replace_all(
      # string = {{var}},
      pattern = '(\\"|“|”)',
      replacement = ""
    ) |>
    # remove terminal white space
    stringr::str_squish(
      # string = {{var}},
    ) |>
    stringr::str_replace_all(
      pattern = " $",
      replacement = ""
    )

  return(chemin_col)

}

#' Raccourcir le chemin en enlevant les exemples entre parenthèses
#'
#' @inheritParams purger_mauvais_char_chemin
#'
#' @return Character. Texte modifié
#'
#' @importFrom stringr str_replace
raccourcir_chemin <- function(var) {

  chemin_col <- 
  # remove parentheticals to abbpreviate paths
    stringr::str_replace_all(
      string = {{var}},
      pattern = "\\(.+\\)",
      replacement = ""
    ) |>
    stringr::str_squish()

  return(chemin_col)

}
