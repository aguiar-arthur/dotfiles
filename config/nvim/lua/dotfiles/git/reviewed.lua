local repo = require("dotfiles.git.repo")
local review = require("dotfiles.git.review")
local session = require("dotfiles.git.session")

local M = {}

M.NETWORK_TIMEOUT_MS = 15000

local function ref(number, kind)
  return ("refs/pr-review/%d/%s"):format(number, kind)
end

local function short(commit)
  return commit:sub(1, 7)
end

local function rev(dir, name)
  return repo.run("-C", dir, "rev-parse", "--verify", "--quiet", name .. "^{commit}")
end

local function tree(dir, name)
  return repo.run("-C", dir, "rev-parse", "--verify", "--quiet", name .. "^{tree}")
end

local function remote(dir, slug)
  local pattern = slug and "[/:]" .. vim.pesc(slug:lower()) .. "$"
  for line in (repo.run("-C", dir, "remote", "-v") or ""):gmatch("[^\n]+") do
    local name, url = line:match("^(%S+)%s+(%S+)")
    if pattern and url and url:lower():gsub("%.git$", ""):find(pattern) then
      return name
    end
  end
  return "origin"
end

function M.target(number, slug, dir, callback)
  if vim.fn.executable("gh") ~= 1 then
    return callback(nil)
  end
  local command = { "gh", "pr", "view", tostring(number), "--json", "baseRefName,headRefOid" }
  if slug then
    vim.list_extend(command, { "--repo", slug })
  end
  vim.system(
    command,
    { text = true, cwd = dir, timeout = M.NETWORK_TIMEOUT_MS },
    vim.schedule_wrap(function(result)
      local ok, data = pcall(vim.json.decode, result.stdout or "")
      callback(result.code == 0 and ok and type(data) == "table" and data or nil)
    end)
  )
end

function M.fetch(number, dir, slug, callback)
  local root = repo.run("-C", dir, "rev-parse", "--show-toplevel")
  local finished = false
  local function finish(pr, why)
    if finished then
      return
    end
    finished = true
    if not pr then
      vim.notify(
        "Could not fetch PR #" .. number .. (why and ": " .. why or ""),
        vim.log.levels.WARN
      )
    end
    callback(pr)
  end
  if not root then
    return finish(nil)
  end
  vim.defer_fn(function()
    finish(nil, "no answer in " .. M.NETWORK_TIMEOUT_MS / 1000 .. " s")
  end, M.NETWORK_TIMEOUT_MS)
  M.target(number, slug, root, function(github)
    github = github or {}
    local options = { remote = remote(root, slug), base = github.baseRefName }
    require("codediff.core.pull_request").fetch(
      number,
      root,
      options,
      vim.schedule_wrap(function(err, revisions)
        local shown = not err and revisions and revisions.head_revision
        local fork = shown and repo.run("-C", root, "merge-base", revisions.base_revision, shown)
        if not fork then
          return finish(nil, err)
        end
        if github.headRefOid and github.headRefOid ~= shown then
          vim.notify(
            ("PR #%d: GitHub has not caught up with its last push, this shows %s"):format(
              number,
              short(shown)
            ),
            vim.log.levels.WARN
          )
        end
        finish({ number = number, dir = root, shown = shown, fork = fork })
      end)
    )
  end)
end

local function record(pr, message)
  local stdin = ("update %s %s\nupdate %s %s\n"):format(
    ref(pr.number, "reviewed"),
    pr.shown,
    ref(pr.number, "reviewed-fork"),
    pr.fork
  )
  vim.system(
    { "git", "-C", pr.dir, "update-ref", "--stdin" },
    { text = true, stdin = stdin },
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        vim.notify(message)
      end
    end)
  )
end

function M.review(number, dir, slug)
  M.fetch(number, dir, slug, function(pr)
    if pr then
      review.expect("PR #" .. number, { number = number })
      vim.cmd.CodeDiff(pr.fork .. "..." .. pr.shown)
    end
  end)
end

local function replayed(pr)
  local number, dir = pr.number, pr.dir
  local old_fork = rev(dir, ref(number, "reviewed-fork"))
  if not old_fork or old_fork == pr.fork then
    return ref(number, "reviewed"), ""
  end
  local merged = repo.run(
    "-C",
    dir,
    "merge-tree",
    "--write-tree",
    "--merge-base=" .. old_fork,
    pr.fork,
    ref(number, "reviewed")
  )
  -- why: commit-tree needs an identity, and this commit never leaves the repository
  local commit = merged
    and repo.run(
      "-C",
      dir,
      "-c",
      "user.name=pr-review",
      "-c",
      "user.email=pr-review@localhost",
      "commit-tree",
      merged:match("^%x+"),
      "-p",
      ref(number, "reviewed"),
      "-m",
      ("PR #%d as reviewed, on its new base"):format(number)
    )
  if not (commit and repo.run("-C", dir, "update-ref", ref(number, "replayed"), commit)) then
    vim.notify(
      ("PR #%d: what you reviewed does not apply to the new base, so the base's changes show too"):format(
        number
      ),
      vim.log.levels.WARN
    )
    return ref(number, "reviewed"), ""
  end
  return ref(number, "replayed"), ", on the new base"
end

function M.since(number, dir, slug)
  local last = rev(dir, ref(number, "reviewed"))
  if not last then
    vim.notify("PR #" .. number .. " was never reviewed to the end here", vim.log.levels.WARN)
    return
  end
  M.fetch(number, dir, slug, function(pr)
    if not pr then
      return
    end
    local nothing = ("Nothing new in PR #%d since %s"):format(number, short(last))
    if pr.shown == last then
      return vim.notify(nothing)
    end
    local from, note = replayed(pr)
    if tree(dir, from) == tree(dir, pr.shown) then
      return record(pr, nothing)
    end
    review.expect(
      ("PR #%d since %s%s"):format(number, short(last), note),
      { number = number, fork = pr.fork }
    )
    vim.cmd.CodeDiff(rev(dir, from), pr.shown)
  end)
end

function M.mark(tab)
  local pr, shown = review.pr(tab), session.revisions(tab)
  if not (pr and shown and shown.target and shown.target:match("^%x+$")) then
    return
  end
  record({
    number = pr.number,
    dir = shown.root,
    shown = shown.target,
    fork = pr.fork or shown.base,
  }, ("PR #%d reviewed up to %s"):format(pr.number, short(shown.target)))
end

return M
