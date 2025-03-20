local M = {}

local au_group = vim.api.nvim_create_augroup("CoredumpyTmpFiles", {})

local function register_delete(path)
  vim.api.nvim_create_autocmd("VimLeave", {
    group = au_group,
    callback = function()
      local file_stat = vim.uv.fs_stat(path)
      if file_stat ~= nil and file_stat.type == "file" then
        os.remove(path)
      end
    end,
  })
end

---@param url string
---@return {owner: string, repo: string, artifact_id: string}?
function M.parse_artifact_url(url)
  local pattern = nil
  if url:match("^https://github.com") ~= nil then
    pattern = "https://github.com/(%w+)/(%w+)/actions/runs/%d+/artifacts/(%d+)"
  elseif url:match("^vscode://") then
    pattern =
      "vscode://gaogaotiantian%.coredumpy%-vscode/load%-github%-artifact%?owner=(%w+)&repo=(%w+)&artifactId=(%d+)"
  else
    error("Unrecognised pattern!")
  end
  if pattern == nil then
    return
  end
  local owner, repo, id = string.match(url, pattern)
  return { owner = owner, repo = repo, artifact_id = id }
end

--- Parse a url to the artifact and return the path to the temporary file that contains the dump
---@param url string
---@param fetch_timeout_ms integer
---@return string?
function M.get_artifact(url, fetch_timeout_ms)
  local artifact_meta = M.parse_artifact_url(url)
  if artifact_meta == nil then
    error(string.format("Failed to parse the url: %s", url), vim.log.levels.ERROR)
  end
  for _, exe in pairs({ "gh", "zcat" }) do
    if vim.fn.executable(exe) ~= 1 then
      error(string.format("%s is not installed.", exe), vim.log.levels.ERROR)
    end
  end

  vim.notify(
    string.format(
      "Fetching artifact %s from %s/%s...",
      artifact_meta.artifact_id,
      artifact_meta.owner,
      artifact_meta.repo
    ),
    vim.log.levels.INFO
  )

  local temp_path = nil
  vim.system({
    "gh",
    "api",
    "-H",
    "Accept: application/vnd.github+json",
    "-H",
    "X-GitHub-Api-Version: 2022-11-28",
    string.format(
      "/repos/%s/%s/actions/artifacts/%s/zip",
      artifact_meta.owner,
      artifact_meta.repo,
      artifact_meta.artifact_id
    ),
  }, { text = false }, function(out)
    if out.code == 0 then
      vim.system({ "zcat" }, { text = false, stdin = out.stdout }, function(out2)
        if out2.code == 0 then
          local temp_file_name = os.tmpname()
          local file, err = io.open(temp_file_name, "wb")
          if err or file == nil then
            vim.schedule_wrap(vim.notify)(
              string.format("Failed to create temporary file for the dump:\n%s", err),
              vim.log.levels.ERROR
            )
          else
            file:write(out2.stdout)
            file:close()
            temp_path = temp_file_name
          end
        else
          vim.schedule_wrap(vim.notify)(out2.stderr, vim.log.levels.ERROR)
        end
      end)
    else
      vim.schedule_wrap(vim.notify)(out.stderr, vim.log.levels.ERROR)
    end
  end)
  vim.wait(fetch_timeout_ms, function()
    return temp_path ~= nil
  end)
  if temp_path == nil then
    vim.schedule_wrap(vim.notify)(
      "Timed out when fetching remote coredumpy file.",
      vim.log.levels.ERROR
    )
  else
    register_delete(temp_path)
  end
  return temp_path
end
return M
