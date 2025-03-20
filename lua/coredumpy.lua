local M = {}

---@class CoreDumpy.SetupOpts
---@field python string|(fun():string)|nil Path to the python interpreter to run coredumpy with.
---@field host string?
---@field port integer?
---@field timeout_ms integer?

---@type CoreDumpy.SetupOpts
local config = { python = nil, host = "127.0.0.1", port = 6742, timeout_ms = 10000 }

---@param opts CoreDumpy.SetupOpts
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  if vim.fn.executable("coredumpy") ~= 1 and config.python == nil then
    config.python = "python"
  end
end

---@param dump_path string
function M.run(dump_path)
  if type(dump_path) ~= "string" then
    error("dump_path must be a string!", vim.log.levels.ERROR)
    return
  end
  local ok, dap = pcall(require, "dap")
  if not ok then
    error("nvim-dap is not found!", vim.log.levels.ERROR)
  end

  local executable
  if config.python == nil and vim.fn.executable("coredumpy") == 1 then
    executable = { command = "coredumpy", args = { "host" } }
  else
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
    executable = {
      command = python,
      args = { "-m", "coredumpy", "host" },
    }
  end

  ---@type dap.ServerAdapter
  dap.adapters["coredumpy"] = {
    executable = executable,
    host = config.host,
    name = string.format("Remote process at '%s@%d'", config.host, config.port),
    options = {
      source_filetype = "python",
    },
    port = config.port,
    type = "server",
  }

  local fs_stats = vim.uv.fs_stat(dump_path)
  if fs_stats == nil or fs_stats.type ~= "file" then
    local fetched_file =
      require("coredumpy.utils").get_artifact(dump_path, config.timeout_ms)
    if fetched_file == nil then
      return
    end
    dump_path = fetched_file
  end
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
