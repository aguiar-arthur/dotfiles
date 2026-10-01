local ok, schemastore = pcall(require, "schemastore")

return {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" }, -- usamos o SchemaStore.nvim
      schemas = ok and schemastore.yaml.schemas() or nil,
    },
  },
}
