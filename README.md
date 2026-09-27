# nathan818's deb-packages

> [!WARNING]
> **This repository is archived and no longer maintained.** I no longer use
> Debian on my desktop, so no new packages or updates will be published. The
> existing [GitHub Releases][github-releases] remain available, but they are
> frozen at their last built version.

This repository contains scripts to create simple Debian packages for some
softwares that I use.

Scripts were set up to run periodically with GitHub Actions, so that a new
version of a supported software would automatically produce a new package. The
packages are stored as [GitHub Releases assets][github-releases]. These scheduled
workflows are disabled now that the repository is archived.

This repository is primarily for my own use. **I don't provide support. I don't
add software on request.**

## Security

Packages built from this repository are **no longer updated**: they are frozen at
their last built version and will **not** receive upstream security fixes,
patches, or dependency upgrades. They may therefore contain known vulnerabilities
and should **not** be used.

Prefer the official upstream packages or your distribution's repositories
whenever they are available.

[github-releases]: https://github.com/nathan818fr/deb-packages/releases
