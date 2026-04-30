# org-links

This is a plugin to prettify links in orgmode files.

A link in orgmode can look like either of these:

```text
Just a link: [[https://github.com]]

A link with a label: [[https://github.com][GitHub]]
```

This plugin instead displays only the link, or if present, only the label, as
shown here.

```text
Just a link: https://github.com

A link with a label: GitHub
```

The underlying raw text is displayed on the current cursor line, so it can
still be viewed and edited.

# Installation

Install via your favorite plugin manager (packer, lazy, whatever) and then:

```lua
require("org-links").setup({
  filetypes = { "org" },
  hl_group = "Underlined",
})
```

# Limitations

If you have the same file open in multiple windows and a link line in visible
in both windows, weird display bugs can happen.

