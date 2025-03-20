vim.api.nvim_create_user_command("Coredumpy", function(args)
  require("coredumpy").run(args.fargs[1]:gsub("^%s*(.-)%s*$", "%1"))
end, { complete = "file", nargs = 1 })
