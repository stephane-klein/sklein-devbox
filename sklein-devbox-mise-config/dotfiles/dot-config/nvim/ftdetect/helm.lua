-- Helm : le parseur Tree-sitter `helm` colore les actions {{ … }} et injecte
-- `yaml` sur le texte qui les entoure.
--
-- Neovim ne détecte pas ces fichiers tout seul, et le ftdetect de helm-ls.nvim
-- n'est chargé qu'une fois le filetype déjà connu : d'où ce fichier, chargé au
-- démarrage. `config/autocmds.lua` arrive trop tard (VeryLazy), donc pas de
-- `vim.filetype.add` là-bas.
--
-- `values.yaml` reçoit `yaml.helm-values`, le filetype attendu par helm-ls pour
-- relier les `.Values` des templates au fichier de valeurs. La coloration reste
-- du YAML : vim.treesitter.language.get_lang ramène un sous-filetype au premier
-- segment avant le point.
vim.filetype.add({
  pattern = {
    [".*/templates/.*%.ya?ml"] = "helm",
    [".*/templates/.*%.tpl"] = "helm",
    [".*/templates/.*%.txt"] = "helm",
    ["values.*%.yaml"] = "yaml.helm-values",
  },
})
