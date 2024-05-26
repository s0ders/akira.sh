---
title: "Modern UNIX Tools"
date: 2024-05-26T17:28:34+02:00
draft: false
---
# Introduction
<!--start-summary-->

If you work in a UNIX terminal on a daily basis, there are tools you need to master. These include: `grep`, `find`, a text editor such as Vim or Emacs, etc.

During the last couple of years, some incredibly cool open-source projects have brought us some new CLI tools to work in a faster and simpler way. This post tries to list those I use the most in my day-to-day life.



# Tools

- [bat](https://github.com/sharkdp/bat), a replacement of `cat` bringing many useful features (e.g., syntax highlighting, Git integration, paging)
- [chezmoi](https://www.chezmoi.io/), a simple tool to manage your dotfiles across multiple machines
- [dive](https://github.com/wagoodman/dive), a tool for exploring Docker image layers and contents
- [fd](https://github.com/sharkdp/fd), a faster and more user-friendly alternative to `find`
- [just](https://github.com/casey/just), a command runner that brings many improvements over [Make](https://www.gnu.org/software/make/)[^1]
- [jq](https://github.com/jqlang/jq), a command-line JSON processor (think `awk` but for JSON)
- [ripgrep](https://github.com/BurntSushi/ripgrep), a line search tool like `grep`, but faster and more user-friendly
- [starship](https://starship.rs/), a tool to customize your prompt in a simple way using TOML
- [tmux](https://github.com/tmux/tmux), a powerful terminal multiplexer, I personally find it more user-friendly than `screen`



[^1]: The main difference between these tools is that Make is a build system whereas `just` is a command runner which avoids having to define `.PHONY` for instance.
