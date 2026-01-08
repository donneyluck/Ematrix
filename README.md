# Ematrix

> [!CAUTION]
> Please note that Ematrix is under active rewrite. The new generation of this
> configuration (branch `ematrix-ng`) will not be compatible with this one as
> it includes multiple breaking changes compared to the `main` branch. Including
> but not limited to, dropping the support of Evil and General **(still, you can
> enable the `obsolete/me-evil` module to have the same experience)**, among
> other things.
>
> Personally, I'm moving to a more mainstream Emacs experience as I started to
> hit the limits of `evil-mode`. I think that using Emacs exclusively via Evil
> hides a lot of Emacs' beauty and creates more problems than it solves
> [personal opinion/experience].
>
> I will cherry pick some relevant commits from `ematrix-ng`, but I won't be
> able to add new features to this branch.
>
> **At some point, the new `ematrix-ng` will become the `main` branch, so if
> you want to stick with this old generation of the framework, we highly
> recommend you to switch to the `legacy` branch**.

[![CI-Linux](https://github.com/abougouffa/ematrix/actions/workflows/ci-linux.yaml/badge.svg)](https://github.com/abougouffa/ematrix/actions/workflows/ci-linux.yaml)
[![CI-MacOS](https://github.com/abougouffa/ematrix/actions/workflows/ci-macos.yaml/badge.svg)](https://github.com/abougouffa/ematrix/actions/workflows/ci-macos.yaml)
[![CI-Windows](https://github.com/abougouffa/ematrix/actions/workflows/ci-windows.yaml/badge.svg)](https://github.com/abougouffa/ematrix/actions/workflows/ci-windows.yaml)

**Ematrix** is a complete and fast Emacs configuration framework.

![Ematrix banner](/docs/images/ematrix-cover.svg)

![Ematrix screenshot](/docs/images/ematrix-screenshot.png)

## Why?

Since a few years, Emacs forms the foundation of my workflow, serving as my
go-to tool for various tasks such as document writing, academic papers writing
and editing, email management, staying updated with news, developing software
using multiple programming languages and for different domains including:
robotics, embedded systems, embedded Linux, CI/CD, among other things.

Before Emacs, I was mainly using VSCode and QtCreator with a little bit of
Vim/Neovim. Hence, I wanted, in the beginning, a VIM-style configuration
framework that is both robust and straightforward.
[Spacemacs](https://github.com/syl20bnr/spacemacs) was the first framework I've
tested, I liked the idea of using `SPC` as a leader key, but I didn't like the
way Spacemacs packs things in layers, and imposes a unique way of writing your
configuration.

I discovered then [Doom Emacs](https://github.com/doomemacs/doomemacs), which I
found a remarkable piece of software that introduced me to the world of Emacs.
Nonetheless, my experience with it turned out to be **less enjoyable** later. In
fact, before I started the [Ematrix](https://github.com/abougouffa/ematrix)
project back in September 2022, I encountered numerous issues with Doom Emacs.
Occasionally, after running the `doom upgrade` command, everything would cease
to function properly. These problems always seemed to arise during my busiest
days, causing unnecessary additional stress. To be honest, I think at that time,
big parts of Doom Emacs where being rewritten, which cased these annoying
breakages then, but I think it should be more stable now. However, Doom Emacs
started to feel overly complex as a configuration framework. It incorporated a
command line interface, an extensive library with extra features, numerous
unnecessary hacks to tweak Emacs behavior for a negligible improvement in
startup time, configuration modules that tightly combined various packages in an
opinionated manner, CI commands, and even a profile manager! Each of these
features introduced extra complexity and more failure points at every layer.

As a result, Ematrix emerged as my personal configuration framework for Emacs,
_and it continues to serve that purpose_. I'm trying to tailor it to my specific
needs while maintaining its modularity and portability. Ematrix is changing
constantly, you can refer to the [change log](/docs/CHANGELOG.md) for more
information about the evolution of Ematrix.

Ematrix was mainly based on Evil and General (for the `SPC` leader), even
though Evil still supported via the `me-evil` module, I'm moving away recently
from Evil to embrace the classic Emacs experience. Vim is awesome, and Evil does
a great job in emulating Vim functionalities in Emacs. However, using Emacs via
Evil hides a lot of Emacs beauty and alters the classical Emacs experience, and
to be honest, Evil is quite slow and sometimes messy, and doesn't integrate well
with other packages. For these reasons and other, I started embracing Emacs as
it is, trying to make use of its features as they are intended to be used.

> [!NOTE]
> Please note that I have no intent or availability to create an alternative to
> Doom Emacs or Spacemacs. While I find joy (like every other Emacser out there)
> in tinkering with Emacs, Ematrix remains just a tool that I use in my
> everyday work, and that I like to share with other Emacsers.

## Install

Open a shell and run:

```shell
git clone --recursive https://github.com/abougouffa/ematrix.git ~/.emacs.d && emacs
```

By executing this command, the repository will be cloned, and Emacs will be
launched. During the initial run, Emacs will automatically install the necessary
packages. You might need to run `M-x ematrix-run-build-functions` when Emacs
loads up to install some extra stuff (build some libraries, install Nerd Fonts,
etc.)

> [!IMPORTANT]
> Please note that I'm using a fresh Emacs 29 *(recommended version)* built from
> the `emacs-29` branch mainly on two machines, one based on Manjaro Linux and
> the other on (the quite old) Debian 10. However, I have set up some basic
> [Github CI actions](https://github.com/abougouffa/ematrix/actions) that
> automatically test running this configuration on Emacs 28, 29 and 30 in
> [Ubuntu
> Linux](https://github.com/abougouffa/ematrix/actions/workflows/ci-linux.yaml)
> and
> [MacOS](https://github.com/abougouffa/ematrix/actions/workflows/ci-macos.yaml)
> and on Emacs 29 in
> [Windows](https://github.com/abougouffa/ematrix/actions/workflows/ci-windows.yaml).
> These actions ensure that Ematrix is "runnable" on these systems; with all
> its modules enabled. However, more testing should be done to validate the
> configuration on systems other than Linux.
>
> I'm trying to support at least Emacs 28.2, so [I back port some of the new
> functions/macros I use to Emacs 28](/core/backports/). Furthermore, Ematrix
> includes the `me-compat` module which loads the `compat` package at early
> stage (just after bootstrapping `straight` and `use-package`), this can
> facilitate porting Ematrix to earlier Emacs versions. However, I've never
> tested Ematrix with versions earlier than 28.2, and I don't plan to do so!

## Customization

To personalize Ematrix, you can add a specific set of files within the default
user configuration directory, which is located by default at `~/.ematrix.d/` or
`.emacs.d/user-config/` (the first to be found). However, if you prefer to use a
different directory, you have the flexibility to do so by setting the
`EMATRIXDIR` environment variable.

### Main configuration files

There are two main files that can be added in the `~/.ematrix.d` directory:

1. The `~/.ematrix.d/modules.el` file contains a list of enabled modules and a
   list of disabled packages (`ematrix-modules` and `ematrix-disabled-packages`
   can be set in this file).
2. The `~/.ematrix.d/config.el` file contains the user configuration and
   customization, you can think of it as your `init.el`, which gets loaded at the
   end of Ematrix' `init.el`!

This repository contains skeleton files for [`modules.el`](/skel/modules.el) and
[`config.el`](/skel/config.el) (under [`skel/`](/skel)). We highly recommend
following the same structure as in the skeleton files, specially the use of
`with-eval-after-load` and `use-package` instead of using `require` directly
(`require` loads the packages immediately, which increases the startup time of
Emacs).

### Machine-specific configuration files

In my workflow, I use mainly the same configuration files across all my machines
(which are traditionally shared in my
[dotfiles](https://github.com/abougouffa/dotfiles) repository). However, I have
some machine-specific (local) configurations that contain some private and
machine-specific configurations. For example, I use them to overwrite the email
address on my workstation, to setup my Email accounts, to setup Forge and Jira
integration in my workstation, and so on.

For this purpose, Ematrix will also check for files in
`~/.ematrix.d/local/{early-config,config,modules}.el` and load them, after the
`~/.ematrix.d/{early-config,config,modules}.el` if they exists.

### Advanced configuration files

Ematrix provides also some advanced customization files, these files can be
used to tweak Ematrix' behavior, add some early initialization code, make
Ematrix runnable on older Emacs versions, etc.

1. The `~/.ematrix.d/early-config.el` file is loaded at the end of Ematrix'
   `early-init.el`. You can use it to set up some early stuff like tweaking the
   UI, overwrite the variables set by Ematrix in `~/.emacs.d/early-init.el`,
   and so on.
2. The `~/.ematrix.d/init-tweaks.el` file is loaded at an [early stage of the
   `init.el` file](/init.el#L175). You can use it to do some useful stuff before
   Ematrix starts to customize packages and load modules. See the comments in
   [`init.el`](/init.el) for more information.

### Environment variables

You can customize Ematrix' behavior via some environment variables.

- `EMATRIX_DIR` or `EMATRIXDIR`: Path for Ematrix user configuration
  directory, if not set, `~/.ematrix.d/` is used.
- `EMATRIX_MSG_LEVEL`: Change message log level, from 1 (only errors) to 4 (all
  messages).
- `EMATRIX_VERBOSE`: Be more verbose (useful for debugging).
- `EMATRIX_DEBUG`: Enable debugging at startup.
- `EMATRIX_ALPHA`: Set frame `background-alpha` to percentage (value from 0 to
  100).
- `EMATRIX_NOT_LAZY`: Load lazy packages immediately after loading Emacs.
- `EMATRIX_ALWAYS_DEMAND`: Load all packages immediately (this works by setting
  `use-package-always-demand` to `t` and `use-package-always-defer` to `nil`.
- `EMATRIX_IGNORE_USER_CONFIG`: space-separated values, used to disables
  loading `~/.ematrix.d/<file>.el` user configuration files. Accepted values
  for `<file>` are: `early-config`, `init-tweaks`, `modules`, `config`,
  `local/early-config`, `local/init-tweaks`, `local/modules` and `local/config`.
  Use `all` to disable all user configuration files.
- `EMATRIX_LOAD_ALL_MODULES`: Load all modules (without taking
  `~/.ematrix.d/modules.el` into account).
- `EMATRIX_BENCHMARK`: Run a benchmark at initialization of Emacs (using
  [`benchmark-init.el`](https://github.com/dholm/benchmark-init-el)) and display
  the results after startup (including lazy packages).
- `EMATRIX_NO_PROXIES`: Set if you have `ematrix-proxies` setup in your
  `early-config.el` but you want to start Emacs without passing by these proxies
  (useful if you use some proxies for work but you want Emacs to start without
  passing by them to be able to download packages).

## Extra documentation
For more information about customization variables, functions and commands
defined by Ematrix, you can refer to the [documentation generated from the
source code](/docs/DOCS.md).

## Troubleshooting

If you experienced an issue with Ematrix, you can take a look at the
[FAQ](/docs/FAQ.md), consult the
[discussions](https://github.com/abougouffa/ematrix/discussions), check [open
issues or open a new one](https://github.com/abougouffa/ematrix/issues).
