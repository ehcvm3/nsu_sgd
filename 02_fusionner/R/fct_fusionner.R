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
          replacement = "produit"
        )
      )
    )

  return(dfs_renommes)

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
