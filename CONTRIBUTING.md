# Contributing to raspi-alpine/builder
We love your input! We want to make contributing to this project as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with GitLab
We use GitLab to host code, to track issues and feature requests, as well as accept merge requests.
Pull requests are also accepted via the GitHub mirror.

## We Use Continuous Intergration (CI), So All Code Changes Happen Through Merge or Pull Requests
Merge requests are the best way to propose changes to the codebase.
We use [GitLab CI](https://docs.gitlab.com/ee/ci/), or on the GitHub mirror [Github Actions](https://github.com/features/actions).
We actively welcome your merge or pull requests:

1. Fork the repo and create your branch from `master`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that merge or pull request!

## Report Bugs and Feature Requests using GitLab's [issues](https://gitlab.com/raspi-alpine/builder/-/issues)
We use GitLab issues to track public bugs and feature requests. Report a bug or feature request by
[opening a new issue](https://gitlab.com/raspi-alpine/builder/-/issues/new); it's that easy!

## Write Bug Reports With Detail, Background, and Sample Code
Attach an archive of a stripped down version of your project to the issue, if needed.
If the bug is more involved a reproducer repo might be more appropriate.

**Great Bug Reports** tend to have:
- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can. [This stackoverflow question](http://stackoverflow.com/q/12488905/180626) illustrates how good sample code looks like that can be reproduced by anyone
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

People *love* thorough bug reports. I'm not even kidding.

## Matrix Room
A Matrix Room exists on matrix.org #raspi-alpine:matrix.org this can be joined from any matrix home server.

## Use a Consistent Coding Style
* The coding style is described in these [shell script guidelines](https://google.github.io/styleguide/shellguide.html)
* It is also checked by [shfmt](https://github.com/mvdan/sh) during the lint stage
* If the merge request does not need to rebuild the GitHub docker image then add `[skip actions]` to the commit message (after line 2)
* If the merge request is a documentation or not build related then add `[skip ci]` to the commit message (after line 2) to skip on GitLab as well

## License
By contributing to the project, you agree that your contributions will be licensed under its [Apache License 2.0](https://spdx.org/licenses/Apache-2.0.html).
Feel free to contact the maintainers if that's a concern.

## References
This is adapted from the GitHub Gist
[briandk/CONTRIBUTING.md](https://gist.github.com/briandk/3d2e8b3ec8daf5a27a62#file-contributing-md),
which is in turn adapted from the open-source contribution guidelines for
[Facebook's Draft](https://github.com/facebook/draft-js/blob/a9316a723f9e918afde44dea68b5f9f39b7d9b00/CONTRIBUTING.md)
