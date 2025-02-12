#' Créer une expression régulière pour identifier les groupes
#'
#' @param groupes Vecteur caractère qui compile les noms de groupe tel qu'ils
#' paraissent dans le questionnaire Designer
#'
#' @return Caractère du format `(groupe1|groupe2|groupe3)`
#'
#' @importFrom glue glue_collapse glue
creer_regexpr_groupe <- function(
  groupes
) {

  # créer un "ou" dans regex en concaténant les noms et les séparant de `|`
  chr_concat <- groupes |>
    glue::glue_collapse(sep = "|")

  # créer une expression pour retrouver un des noms, en entourant l'expression
  # précédante de parenthèses
  chr_regexpr <- glue::glue("({chr_concat})")

  return(chr_regexpr)

}

#' Harmoniser le nom de variables dans les bases
#'
#' @description
#' Renommer les variables en enlevant la partie qui correspond au nom de
#' groupe de produit.
#'
#' @param liste_df Liste. Contient les bases de donnée du même format (e.g. base
#' de produits, d'unités absentes, d'unités retrouvées, de relevés)
#' @param regexpr_groupe Caractère. Expression régulière qui décrit les bouts
#' texte qui correspond aux noms de groupe dans les noms de variables.
#'
#' @return Liste. Contient les bases de données d'entrée avec les noms de
#' variable harmonisés à travers les bases de sorte à pouvoir les concaténer
#'
#' @importFrom purrr map
#' @importFrom dplyr rename_with everything matches
#' @importFrom stringr str_replace
#' @importFrom glue glue
harmoniser_noms_vars <- function(
  liste_df,
  regexpr_groupe
) {

  dfs_renommes <- liste_df |>
    # remove product name from all non-ID variables
    # select both product name and preceding underscore
    purrr::map(
      .f = ~ dplyr::rename_with(
        .data = .x,
        .cols = dplyr::everything(),
        .fn = ~ stringr::str_replace(
          string = .x,
          pattern = glue::glue("_{regexpr_groupe}"),
          replacement = ""
        )
      )
    ) |>
    # replace product name in ID variable with `produit`
    purrr::map(
      .f = ~ dplyr::rename_with(
        .data = .x,
        .cols = dplyr::matches(glue::glue("{regexpr_groupe}__id")),
        .fn = ~ stringr::str_replace(
          string = .x,
          pattern = glue::glue("{regexpr_groupe}(?=__id)"),
          replacement = "produits"
        )
      )
    )

  return(dfs_renommes)

}

#' Identifier la base principale au niveau marché
#'
#' @description
#' Par logique d'exclusion, identifier la base principale. Autrement dit,
#' la base qui n'est ni une base produit/unité/taille ni une base de SuSo.
#'
#' @param dir Caractère. Chemin du répertoire qui contient toutes les bases
#' d'une version de l'appli CAPI.
#'
#' @return Caractère. Chemin de la base principale (marché) dans le répertoire
#'
#' @importFrom glue glue_collapse glue
#' @importFrom fs dir_ls path_file
#' @importFrom stringr str_detect
identifier_base_marche <- function(dir) {

  groupes_or <- glue::glue_collapse(
    x = groupes,
    sep = "|"
  )

  chemin_fichiers <- dir |>
    fs::dir_ls(
      type = "file",
      recurse = FALSE
    )

  fichiers <- fs::path_file(chemin_fichiers)

  quel_fichier <- stringr::str_detect(
    string = fichiers,
    pattern = glue::glue(
      "^(?!(assignment|interview|unites|tailles|{groupes_or})).+\\.dta"
    )
  )

  marche_nom_fichier <- chemin_fichiers[quel_fichier]

  return(marche_nom_fichier)

}

#' Fusionner la base du niveau marché
#'
#' @param dir_parent Caractère. Chemin où les bases brutes sont téléchargées.
#'
#' @return Data frame. Base fusionnée.
#'
#' @importFrom fs dir_ls
#' @importFrom purrr map_chr map
#' @importFrom haven read_dta
#' @importFrom dplyr bind_rows
fusionner_marche <- function(dir_parent) {

  dirs_enfant <- fs::dir_ls(
    path = dir_parent,
    type = "directory",
    recurse = FALSE
  )

  chemins_marche <- dirs_enfant |>
    purrr::map_chr(
      .f = ~ identifier_base_marche(dir = .x)
    )

  marche_df <- chemins_marche |>
    purrr::map(
      .f = ~ haven::read_dta(file = .x)
    ) |>
    dplyr::bind_rows()

}

#' Fusionner les bases du niveau produit dans un répertoire donné
#'
#' @param dir Caractère. Chemin du répertoire d'une version du qnr NSU.
#' @param regexpr Caractère. Expression régulière qui cible la partie groupe
#' de produits du nom des variables.
#'
#' @return Data frame. Contient la fusion des bases cible du répertoire cible.
#'
#' @importFrom glue glue
#' @importFrom fs dir_ls
#' @importFrom purrr map
#' @importFrom dplyr bind_rows
fusionner_produits <- function(
  dir,
  regexpr
) {

  # construire une expression pour sélectionner le nom du groupe ainsi que
  # le `_` qui le précède
  regexpr_produit <- glue::glue("(?<!_){regexpr}")

  # compiler le lien des fichiers cible
  chemins_produits <- fs::dir_ls(
    path = dir,
    type = "file",
    regexp = regexpr_produit,
    perl = TRUE
  )

  df_produits <- chemins_produits |>
    # ingéger les bases produits
    purrr::map(.f = ~ haven::read_dta(file = .x)) |>
    # harmoniser le nom des variables en enlevant la partie groupe de produit
    harmoniser_noms_vars(regexpr_groupe = regexpr) |>
    # concaténer les bases en une seule
    dplyr::bind_rows()

  return(df_produits)

}

#' Fusionner les bases d'unités retrouvées dans un répertoire donné
#'
#' @param dir Caractère. Chemin du répertoire d'une version du qnr NSU.
#' @param regexpr Caractère. Expression régulière qui cible la partie groupe
#' de produits du nom des variables.
#'
#' @return Data frame. Contient la fusion des bases cible du répertoire cible.
#'
#' @importFrom glue glue
#' @importFrom fs dir_ls
#' @importFrom purrr map
#' @importFrom dplyr bind_rows
fusionner_unites_retrouvees <- function(
  dir,
  regexpr
) {

  regexpr_unites <- glue::glue("unites_{regexpr}")

  chemins_unites <- fs::dir_ls(
    path = dir,
    type = "file",
    regexp = regexpr_unites,
    perl = TRUE
  )

  df_unites_retrouvees <- chemins_unites |>
    # ingéger les bases produits
    purrr::map(.f = ~ haven::read_dta(file = .x)) |>
    # harmoniser le nom des variables en enlevant la partie groupe de produit
    harmoniser_noms_vars(regexpr_groupe = regexpr) |>
    # concaténer les bases en une seule
    dplyr::bind_rows()

  return(df_unites_retrouvees)

}

#' Fusionner les bases d'unités absentes dans un répertoire donné
#'
#' @param dir Caractère. Chemin du répertoire d'une version du qnr NSU.
#' @param regexpr Caractère. Expression régulière qui cible la partie groupe
#' de produits du nom des variables.
#'
#' @return Data frame. Contient la fusion des bases cible du répertoire cible.
#'
#' @importFrom fs dir_ls
#' @importFrom purrr map
#' @importFrom dplyr bind_rows
fusionner_unites_absentes <- function(
  dir,
  regexpr
) {

  chemins_unites <- fs::dir_ls(
    path = dir,
    type = "file",
    regexp = "unites_absentes",
    perl = TRUE
  )

  df_unites_absentes <- chemins_unites |>
    # ingéger les bases produits
    purrr::map(.f = ~ haven::read_dta(file = .x)) |>
    # harmoniser le nom des variables en enlevant la partie groupe de produit
    harmoniser_noms_vars(regexpr_groupe = regexpr) |>
    # concaténer les bases en une seule
    dplyr::bind_rows()

  return(df_unites_absentes)

}

#' Fusionner les bases de relevés de poid et de prix dans un répertoire donné
#'
#' @param dir Caractère. Chemin du répertoire d'une version du qnr NSU.
#' @param regexpr Caractère. Expression régulière qui cible la partie groupe
#' de produits du nom des variables.
#'
#' @return Data frame. Contient la fusion des bases cible du répertoire cible.
#'
#' @importFrom fs dir_ls
#' @importFrom purrr map
#' @importFrom dplyr bind_rows
fusionner_releves <- function(
  dir,
  regexpr
) {

  chemins_releves <- fs::dir_ls(
    path = dir,
    regexp = "tailles_",
    perl = TRUE
  )

  df_releves <- chemins_releves |>
    # ingéger les bases produits
    purrr::map(.f = ~ haven::read_dta(file = .x)) |>
    # harmoniser le nom des variables en enlevant la partie groupe de produit
    harmoniser_noms_vars(regexpr_groupe = regexpr) |>
    # concaténer les bases en une seule
    dplyr::bind_rows()

  return(df_releves)

}

#' Obtenir le chemin des données de la dernière version de l'appli CAPI
#'
#' @param dir Caractère. Chemin des données téléchargée.
#'
#' @return Caractère. Chemin complet de la dernière version.
#'
#' @importFrom fs dir_ls path_file path_ext_remove path
#' @importFrom stringr str_extract
obtenir_chemin_der_version <- function(dir) {

  # créer une de fichiers zip sans extension
  # qui serviront de nom de sous-répertoires
  dirs <- dir |>
    fs::dir_ls(
      type = "file",
      regexp = "\\.zip"
    ) |>
    fs::path_file() |>
    fs::path_ext_remove()

  # extraire la version
  versions <- dirs |>
    stringr::str_extract(pattern = "(?<=_)([0-9])(?=_STATA_All)") |>
    as.numeric()

  # obtenir l'indice de la version la plus élevée
  max_version_index <- which(versions == max(versions))

  # sélectionner le sous-répertoire avec la dernière version
  sous_dir_derniere_version <- dirs[max_version_index]

  # construire le chemin complet de ce sous répertoire
  dir_derniere_version <- fs::path(dir, sous_dir_derniere_version)

  return(dir_derniere_version)

}

#' Obtenir les chemins des représentations structurées du questionnaire
#'
#' @description
#' En particulier, le chemin du questionnaire en format JSON et du répertoire
#' où se trouve les catégorie réutilisables.
#'
#' @param dir Caractère. Chemin des données de la dernière version du
#' questionnaire.
#'
#' @return Liste< Contient:
#' - Chemin du fichier JSON : `chemin_qnr_json`
#' - Répertoire des catégories réutilisables : `dir_categories`
#'
#' @importFrom fs path
#' @importFrom susoflows unzip_to_dir
obtenir_chemins_qnr <- function(dir) {

  # construire le chemin à partir de celui de la dernière version
  dir_qnr <- fs::path(dir, "Questionnaire")

  # décomprimer le contenu du questionnaire
  susoflows::unzip_to_dir(dir_qnr)
  dir_qnr_contenu <- fs::path(dir_qnr, "content")

  # construire chemins du fichier JSON
  chemins_qnr <- list(
    chemin_qnr_json = fs::path(dir_qnr_contenu, "document.json"),
    dir_categories = fs::path(dir_qnr_contenu, "Categories")
  )

  return(chemins_qnr)

}
