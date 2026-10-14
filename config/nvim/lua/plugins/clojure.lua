return {
  {
    "Olical/conjure",
    ft = "clojure",
    keys = {
      {
        "<localleader>cj",
        function()
          require("dotfiles.clojure").jack_in()
        end,
        ft = "clojure",
        desc = "Start the REPL and connect (jack-in)",
      },
    },
    init = function()
      vim.g["conjure#filetypes"] = { "clojure" }
      vim.g["conjure#mapping#doc_word"] = false
      vim.g["conjure#mapping#def_word"] = false
      vim.g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = false
    end,
  },
  { "julienvincent/nvim-paredit", ft = "clojure", opts = {} },
}
