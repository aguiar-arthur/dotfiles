return {
  capabilities = { general = { positionEncodings = { "utf-16" } } },
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
}
