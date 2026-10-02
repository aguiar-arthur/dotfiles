-- LaTeX snippets (LuaSnip). Loaded by lua/plugins/completion.lua.
--
--  * `autosnippets`: expand by themselves when the trigger is typed (context-aware:
--    text/math, via vimtex#syntax#in_mathzone).
--  * `snippets`: show up in the completion menu (blink.cmp) and expand with <CR>/<Tab>.
--
-- Inside a snippet, <Tab>/<S-Tab> jump between fields.

local ls = require("luasnip")
local s, t, i, f = ls.snippet, ls.text_node, ls.insert_node, ls.function_node
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta

-- Context -------------------------------------------------------------------
local function in_math()
  local ok, r = pcall(vim.fn["vimtex#syntax#in_mathzone"])
  return ok and r == 1
end
local function in_text() return not in_math() end

local function cap(n)
  return f(function(_, snip) return snip.captures[n] end)
end

-- Helpers for declaring snippets ------------------------------------------------
local snippets, autosnippets = {}, {}

---@param ctx string|table  trigger or LuaSnip context
---@param nodes table
---@param cond? fun():boolean
---@param word? boolean  false = expands even when attached to another word
local function auto(ctx, nodes, cond, word)
  ctx = type(ctx) == "string" and { trig = ctx } or ctx
  ctx.snippetType = "autosnippet"
  if word == false then ctx.wordTrig = false end
  table.insert(autosnippets, s(ctx, nodes, { condition = cond }))
end

local function snip(ctx, nodes, cond)
  ctx = type(ctx) == "string" and { trig = ctx } or ctx
  table.insert(snippets, s(ctx, nodes, { condition = cond }))
end

-- Text mode: environments -------------------------------------------------------
auto("mk", fmta("$<>$<>", { i(1), i(0) }), in_text)
auto("dm", fmta("\\[\n\t<>\n\\]<>", { i(1), i(0) }), in_text)
auto("beg", fmta("\\begin{<>}\n\t<>\n\\end{<>}", { i(1), i(0), rep(1) }), in_text)

local function env(trig, name, body)
  snip({ trig = trig, dscr = "\\begin{" .. name .. "}" },
    fmta("\\begin{" .. name .. "}\n\t" .. (body or "") .. "<>\n\\end{" .. name .. "}", { i(0) }))
end
env("eqn", "equation*")
env("eqnn", "equation")
env("ali", "align*")
env("alin", "align")
env("gat", "gather*")
env("cas", "cases")
env("pmat", "pmatrix")
env("bmat", "bmatrix")
env("thm", "theorem")
env("lem", "lemma")
env("prf", "proof")
env("def", "definition")
env("exa", "example")
env("rem", "remark")
env("abs", "abstract")
env("cen", "center")
env("ite", "itemize", "\\item ")
env("enu", "enumerate", "\\item ")
env("desc", "description", "\\item ")

snip("fig", fmta([[
\begin{figure}[<>]
	\centering
	\includegraphics[width=<>\linewidth]{<>}
	\caption{<>}
	\label{fig:<>}
\end{figure}<>]], { i(1, "htbp"), i(2, "0.8"), i(3), i(4), i(5), i(0) }))

snip("tab", fmta([[
\begin{table}[<>]
	\centering
	\caption{<>}
	\label{tab:<>}
	\begin{tabular}{<>}
		\hline
		<>
		\hline
	\end{tabular}
\end{table}<>]], { i(1, "htbp"), i(2), i(3), i(4, "lcc"), i(5), i(0) }))

-- Text mode: structure and references ---------------------------------------------
snip("sec", fmta("\\section{<>}\n\\label{sec:<>}\n<>", { i(1), i(2), i(0) }))
snip("ssec", fmta("\\subsection{<>}\n\\label{sec:<>}\n<>", { i(1), i(2), i(0) }))
snip("sssec", fmta("\\subsubsection{<>}\n\\label{sec:<>}\n<>", { i(1), i(2), i(0) }))
snip("par", fmta("\\paragraph{<>} <>", { i(1), i(0) }))
snip("cit", fmta("\\cite{<>}<>", { i(1), i(0) }))
snip("citp", fmta("\\citep{<>}<>", { i(1), i(0) }))
snip("citt", fmta("\\citet{<>}<>", { i(1), i(0) }))
snip("ref", fmta("\\ref{<>}<>", { i(1), i(0) }))
snip("eqr", fmta("\\eqref{<>}<>", { i(1), i(0) }))
snip("lab", fmta("\\label{<>}<>", { i(1), i(0) }))
snip("pkg", fmta("\\usepackage{<>}", { i(1) }))
snip("pkgo", fmta("\\usepackage[<>]{<>}", { i(1), i(2) }))
snip("item", fmta("\\item <>", { i(0) }))
snip("tbf", fmta("\\textbf{<>}<>", { i(1), i(0) }))
snip("tit", fmta("\\textit{<>}<>", { i(1), i(0) }))
snip("ttt", fmta("\\texttt{<>}<>", { i(1), i(0) }))
snip("emp", fmta("\\emph{<>}<>", { i(1), i(0) }))
snip("url", fmta("\\url{<>}<>", { i(1), i(0) }))
snip("foot", fmta("\\footnote{<>}<>", { i(1), i(0) }))

snip("doc", fmta([[
\documentclass[<>]{<>}

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[<>]{babel}
\usepackage{amsmath, amssymb, amsthm}
\usepackage{graphicx}
\usepackage{hyperref}

\title{<>}
\author{<>}
\date{\today}

\begin{document}
\maketitle

<>

\end{document}
]], { i(1, "12pt,a4paper"), i(2, "article"), i(3, "brazil"), i(4), i(5), i(0) }))

-- Beamer (slides) -----------------------------------------------------------------
snip("bdoc", fmta([[
\documentclass[aspectratio=169]{beamer}

\usetheme{<>}
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage[<>]{babel}
\usepackage{amsmath, amssymb}
\usepackage{graphicx}

\title{<>}
\author{<>}
\date{\today}

\begin{document}

\frame{\titlepage}

\begin{frame}{Outline}
	\tableofcontents
\end{frame}

\section{<>}

\begin{frame}{<>}
	<>
\end{frame}

\end{document}
]], { i(1, "Madrid"), i(2, "english"), i(3), i(4), i(5, "Introduction"), i(6, "First slide"), i(0) }))

snip("frm", fmta("\\begin{frame}{<>}\n\t<>\n\\end{frame}<>", { i(1), i(0), i(2) }))
snip("fimg", fmta("\\begin{frame}{<>}\n\t\\centering\n\t\\includegraphics[width=<>\\textwidth]{<>}\n\\end{frame}<>", { i(1), i(2, "0.8"), i(3), i(0) }))
snip("col", fmta("\\begin{columns}\n\t\\begin{column}{0.5\\textwidth}\n\t\t<>\n\t\\end{column}\n\t\\begin{column}{0.5\\textwidth}\n\t\t<>\n\t\\end{column}\n\\end{columns}<>", { i(1), i(2), i(0) }))
snip("blk", fmta("\\begin{block}{<>}\n\t<>\n\\end{block}<>", { i(1), i(0), i(2) }))
snip("ablk", fmta("\\begin{alertblock}{<>}\n\t<>\n\\end{alertblock}<>", { i(1), i(0), i(2) }))
snip("pau", t("\\pause"))

-- Math mode: autosnippets ------------------------------------------------------
-- Fractions: `a//` → \frac{a}{}, `(a+b)//` → \frac{a+b}{}
auto({ trig = "([%w%^_\\]+)//", trigEngine = "pattern" }, fmta("\\frac{<>}{<>}<>", { cap(1), i(1), i(0) }), in_math, false)
auto({ trig = "(%b())//", trigEngine = "pattern" }, fmta("\\frac{<>}{<>}<>", {
  f(function(_, sn) return sn.captures[1]:sub(2, -2) end), i(1), i(0),
}), in_math, false)
auto("//", fmta("\\frac{<>}{<>}<>", { i(1), i(2), i(0) }), in_math, false)

-- Sub/superscripts: `x2` → x_2 ; `__` → _{} ; `td` → ^{} ; `sr` → ^2 ; `cb` → ^3
auto({ trig = "(%a)(%d)", trigEngine = "pattern" }, fmta("<>_<>", { cap(1), cap(2) }), in_math)
auto("__", fmta("_{<>}<>", { i(1), i(0) }), in_math, false)
auto("td", fmta("^{<>}<>", { i(1), i(0) }), in_math, false)
auto("sr", t("^2"), in_math, false)
auto("cb", t("^3"), in_math, false)

-- Symbols
local symbols = {
  ["!="] = "\\neq", ["<="] = "\\leq", [">="] = "\\geq", ["->"] = "\\to", ["<-"] = "\\gets",
  ["=>"] = "\\implies", ["=<"] = "\\impliedby", ["<=>"] = "\\iff", ["~~"] = "\\approx",
  ["..."] = "\\dots", ["**"] = "\\cdot", ["xx"] = "\\times", ["ooo"] = "\\infty",
  ["RR"] = "\\mathbb{R}", ["NN"] = "\\mathbb{N}", ["ZZ"] = "\\mathbb{Z}",
  ["QQ"] = "\\mathbb{Q}", ["CC"] = "\\mathbb{C}", ["EE"] = "\\exists", ["AA"] = "\\forall",
  ["inn"] = "\\in", ["notin"] = "\\notin", ["sub"] = "\\subset", ["cap"] = "\\cap", ["cup"] = "\\cup",
  ["emp"] = "\\emptyset", ["pm"] = "\\pm", ["nabla"] = "\\nabla",
}
for trig, out in pairs(symbols) do
  -- alphabetic triggers respect word boundaries; symbols do not
  auto(trig, t(out), in_math, trig:match("^%a+$") ~= nil)
end

-- Greek letters: `;a` → \alpha, `;G` → \Gamma ...
local greek = {
  a = "alpha", b = "beta", g = "gamma", G = "Gamma", d = "delta", D = "Delta",
  e = "epsilon", E = "varepsilon", z = "zeta", h = "eta", t = "theta", T = "Theta",
  k = "kappa", l = "lambda", L = "Lambda", m = "mu", n = "nu", x = "xi", X = "Xi",
  p = "pi", P = "Pi", r = "rho", s = "sigma", S = "Sigma", f = "varphi", F = "Phi",
  c = "chi", y = "psi", Y = "Psi", o = "omega", O = "Omega",
}
for key, name in pairs(greek) do
  auto(";" .. key, t("\\" .. name), in_math, false)
end

-- Operators and structures
auto("sum", fmta("\\sum_{<>=<>}^{<>} <>", { i(1, "i"), i(2, "1"), i(3, "n"), i(0) }), in_math)
auto("prod", fmta("\\prod_{<>=<>}^{<>} <>", { i(1, "i"), i(2, "1"), i(3, "n"), i(0) }), in_math)
auto("lim", fmta("\\lim_{<> \\to <>} <>", { i(1, "n"), i(2, "\\infty"), i(0) }), in_math)
auto("int", fmta("\\int <>", { i(0) }), in_math)
auto("dint", fmta("\\int_{<>}^{<>} <>", { i(1, "0"), i(2, "1"), i(0) }), in_math)
auto("part", fmta("\\frac{\\partial <>}{\\partial <>}<>", { i(1), i(2), i(0) }), in_math)
auto("sq", fmta("\\sqrt{<>}<>", { i(1), i(0) }), in_math)
auto("txt", fmta("\\text{<>}<>", { i(1), i(0) }), in_math)
auto("bar", fmta("\\overline{<>}<>", { i(1), i(0) }), in_math)
auto("hat", fmta("\\hat{<>}<>", { i(1), i(0) }), in_math)
auto("vec", fmta("\\vec{<>}<>", { i(1), i(0) }), in_math)
auto("mcal", fmta("\\mathcal{<>}<>", { i(1), i(0) }), in_math)
auto("mbb", fmta("\\mathbb{<>}<>", { i(1), i(0) }), in_math)
auto("mbf", fmta("\\mathbf{<>}<>", { i(1), i(0) }), in_math)

-- Auto-sizing delimiters: `lr(` → \left( ... \right)
auto("lr(", fmta("\\left( <> \\right)<>", { i(1), i(0) }), in_math, false)
auto("lr[", fmta("\\left[ <> \\right]<>", { i(1), i(0) }), in_math, false)
auto("lr{", fmta("\\left\\{ <> \\right\\}<>", { i(1), i(0) }), in_math, false)
auto("lr|", fmta("\\left| <> \\right|<>", { i(1), i(0) }), in_math, false)
auto("norm", fmta("\\left\\| <> \\right\\|<>", { i(1), i(0) }), in_math)

-- Common functions: `sin` → \sin etc. (only if they don't already have the backslash)
for _, fn in ipairs({ "sin", "cos", "tan", "log", "ln", "exp", "max", "min", "arcsin", "arccos", "arctan" }) do
  auto({ trig = "([^\\%a])" .. fn, trigEngine = "pattern", wordTrig = false }, { cap(1), t("\\" .. fn) }, in_math)
end

return snippets, autosnippets
