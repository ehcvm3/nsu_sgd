# ==============================================================================
# confirmer l'installation d'outils de système requis
# ==============================================================================

# compiler les packages requis pour la confirmation
pkgs_pour_confirmer <- c(
  "pkgbuild",
  "cli",
  "quarto"
)

# installer d'éventuels packages absents
# pour chaque package :
# - confirmer si c'est absent
# - installer le si c'est le cas
base::lapply(
  X = pkgs_pour_confirmer,
  FUN = function(x) {
    if (
      !base::require(
        x,
        quietly = TRUE,
        warn.conflicts = FALSE,
        character.only = TRUE
      )
    ) {
      base::message(paste0("Installation de ", x, "en cours"))
      utils::install.packages(
        x,
        quiet = TRUE
      )
    }
  }
)

# exécuter la confirmation
source("R/01_confirmer_outils_systeme.R")

# ==============================================================================
# entamer le montage de renv
# ==============================================================================

source("renv/activate.R")
