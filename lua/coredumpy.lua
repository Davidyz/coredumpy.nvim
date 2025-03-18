local M = {}

---@class CoreDumpy.SetupOpts
---@field python string|(fun():string)|nil Path to the python interpreter to run coredumpy with.
---@field host string?
---@field port integer?

---@type CoreDumpy.SetupOpts
local config = { python = "python", host = "127.0.0.1", port = 6742 }

---@param opts CoreDumpy.SetupOpts
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

---@param dump_path string
function M.run(dump_path)
  if
    type(dump_path) ~= "string"
    or vim.uv.fs_stat(dump_path) == nil
    or vim.uv.fs_stat(dump_path).type ~= "file"
  then
    error("dump_path must be a file!", vim.log.levels.ERROR)
    return
  end
  local ok, dap = pcall(require, "dap")
  if not ok then
    error("nvim-dap is not found!", vim.log.levels.ERROR)
  end

  ---@type string
  local python
  if type(config.python) == "function" then
    python = config.python()
  elseif type(config.python) == "string" then
    python = tostring(config.python)
  else
    error("Failed to detect the python interpreter.", vim.log.levels.ERROR)
  end

  assert(type(python) == "string")
  ---@type dap.ServerAdapter
  dap.adapters["coredumpy"] = {
    executable = {
      command = python,
      args = { "-m", "coredumpy", "host" },
    },
    host = config.host,
    name = string.format("Remote process at '%s@%d'", config.host, config.port),
    options = {
      source_filetype = "python",
    },
    port = config.port,
    type = "server",
  }

  dap.run({
    type = "coredumpy",
    request = "launch",
    name = "Coredumpy",
    program = dump_path,
    pathMappings = {
      {
        localRoot = "${workspaceFolder}",
        remoteRoot = ".",
      },
    },
  }, { new = true })
end

return M
