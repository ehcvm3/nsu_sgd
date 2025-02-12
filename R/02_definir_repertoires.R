# chemins

# 01 - obtenir
dir_obtenir <- here::here("01_obtenir")
dir_donnees_telechargees <- fs::path(dir_obtenir, "01_donnees")
dir_images_telechargees <- fs::path(dir_obtenir, "02_images")

# 02 - fusionner
dir_fusionner <- here::here("02_fusionner")
dir_donnees_fusionnees <- fs::path(dir_fusionner, "donnees")

# 03 - classer
dir_classer <- here::here("03_classer")
dir_images_classees <- fs::path(dir_classer, "images")

groupes <- c(
  "cereales", "viandes", "poissons", "laitier", "huiles",
  "fruits", "legumes", "leg_tub", "sucreries", "epices", "boissons"
)
