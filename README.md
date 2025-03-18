# Coredumpy.nvim
> Use [coredumpy](https://github.com/gaogaotiantian/coredumpy) with [nvim-dap](https://github.com/mfussenegger/nvim-dap)!

[Coredumpy](https://github.com/gaogaotiantian/coredumpy) is a Python post-mortem
debugging tool. It takes a snapshot of failed tests and saves the internals of
the program into a dump file to be inspected later. This plugin, inspired by
[the VSCode counterpart created by the creator of coredumpy](https://marketplace.visualstudio.com/items?itemName=gaogaotiantian.coredumpy-vscode)
creates a [neovim DAP session](https://github.com/mfussenegger/nvim-dap) so that 
you can inspect a dump file in your favourite editor.

## Installation & Configuration

[lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "Davidyz/coredumpy.nvim",
  cmd = { "Coredumpy" },
  opts = {
    python = "python3",
    host = "127.0.0.1",
    port = 6742,
  },
}
```

`host` and `port` are hardcoded in coredumpy, so it's usually not necessary to
touch them. `python` would be the path to your interpreter. If you're using
[venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim), you
can use the following so that this plugin automatically pick up the virtual
environment from venv-selector:

```lua
{
  "Davidyz/coredumpy.nvim",
  cmd = { "Coredumpy" },
  opts = function()
    return {
      python = require("venv-selector").python(),
    },
  end,
  dependencies = { "mfussenegger/nvim-dap" }
}
```

You'll also need to have [Coredumpy](https://github.com/gaogaotiantian/coredumpy) 
installed on your system.

> [!WARNING]
> At the moment, this plugin (nvim-dap, to be specific) only works with 
> [this commit](https://github.com/gaogaotiantian/coredumpy/commit/0f9164a67621517e3bd4c6169a3948fcc34beafb)
> or later. You'll need to install coredumpy from source. This'll be resolved
> once the upstream makes a new release.

## Usage
This plugin tries to replicate the behaviour of the 
[VSCode counterpart](https://marketplace.visualstudio.com/items?itemName=gaogaotiantian.coredumpy-vscode). 
It's an inspector of a dump file produced by [Coredumpy](https://github.com/gaogaotiantian/coredumpy).

Suppose your dump file is located at `path/to/dump/file.dump`, you can use the
following user command to initialise a debugging process: `:Coredumpy path/to/dump/file.dump`.
You'll be able to explore the variables in the failed test cases and perform
certain actions in the REPL:

![](./images/nvim-dap-ui.png)
> The UI is powered by [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui).
> [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view) _should_ work too
> but I haven't tested it because I don't use nvim nightly.

> For instructions to use coredumpy, see the 
> [upstream repo](https://github.com/gaogaotiantian/coredumpy) and 
> [this post](https://gaogaotiantian.medium.com/post-mortem-debugging-with-coredumpy-3b312f46354d)
> from the creator of coredumpy.

## Credits
- [@gaogaotiantian](https://github.com/gaogaotiantian) for creating
  [coredumpy](https://github.com/gaogaotiantian/coredumpy) and fixing the reference ID issue;
- [debugpy.nvim](https://github.com/HiPhish/debugpy.nvim) for nvim-dap related
  code.
