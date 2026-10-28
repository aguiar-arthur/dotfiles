local T = dofile(vim.env.DOT .. "/tests/lib.lua")

local target = { kept = "real" }
local ran = {}

T.case("a crash", function()
  T.stub(target, "kept", "stub")
  T.stub(target, "added", "stub")
  T.stub(vim.env, "DOTFILES_LIB_CHECK", "stub")
  ran[#ran + 1] = "crash"
  error("boom")
end)
T.case("after the crash", function()
  ran[#ran + 1] = "after"
end)

local failed = T.failed
T.failed = {}
T.eq("the case after a crash still runs", ran, { "crash", "after" })
T.eq("a crash is reported by its case, once", #failed, 1)
T.eq(
  "the report names the case and the error",
  failed[1] and failed[1]:match("^a crash: crashed: .*boom$") ~= nil,
  true
)
T.eq("a stub is undone after a crash", target.kept, "real")
T.eq("a stubbed nil comes back as nil", target.added, nil)
T.eq("vim.env comes back too", vim.env.DOTFILES_LIB_CHECK, nil)

T.case("a pass", function()
  T.stub(target, "kept", "first")
  T.stub(target, "kept", "second")
end)
T.eq("stubs are undone in reverse order after a pass", target.kept, "real")
T.eq("a pass reports nothing", #T.failed, 0)

T.done()
