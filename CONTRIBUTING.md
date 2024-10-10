# Contributing to GleoJSON

Thank you for your interest in contributing to GleoJSON! We welcome contributions from the community to help improve and grow this project. This document outlines the process for contributing to GleoJSON.

## Getting Started

1. Fork the repository on GitHub.
1. Clone your fork locally:
   ```
   git clone https://github.com/guria/gleojson.git
   cd gleojson
   ```
1. Set up your development environment with Gleam. If you haven't installed Gleam yet, follow the [official installation guide](https://gleam.run/getting-started/index.html).
1. Setup git hooks with `git config core.hooksPath .hooks` and create `.hooks/setup_env` script if your Gleam executable provided by a version manager like `asdf`.

## Making Changes

1. Create a new branch for your feature or bug fix:
   ```
   git checkout -b your-feature-branch
   ```
1. Make your changes in the relevant files under the `src/` directory.
1. Add or update tests as necessary in the `test/` directory.
1. Run the tests to ensure your changes don't break existing functionality:
   ```
   gleam test
   ```
1. Update the documentation if your changes affect the public API or user-facing features.
1. Run `gleam run -m scripts/embed_examples -- README.md` to update usage example embed into README.md.

## Submitting Changes

1. Commit your changes with a clear and descriptive commit message:

   ```
   git commit -am -s "Add a brief description of your changes"
   ```

   By using the `-s` option, you are signing off your commit, which certifies that you accept the Developer Certificate of Origin (DCO) as defined in this document.

1. Push your branch to your fork on GitHub:
   ```
   git push origin your-feature-branch
   ```
1. Open a pull request against the main repository's `main` branch.
1. In your pull request description, explain the changes you've made and why they're necessary.

## Code Style and Standards

- Write clear, concise comments and documentation.
- Ensure your code is well-tested.

## Reporting Issues

If you find a bug or have a suggestion for improvement:

1. Check the [GitHub Issues](https://github.com/guria/gleojson/issues) to see if it has already been reported.
1. If not, open a new issue, providing as much detail as possible about the problem or suggestion.

## Community and Communication

- Join the [Gleam Discord](https://discord.gg/Fm8Pwmy) for discussions and questions.
- Be respectful and considerate in all interactions.

## License

By contributing to GleoJSON, you agree that your contributions will be licensed under the project's [LICENSE](LICENSE) file.

Thank you for contributing to GleoJSON!

# Developer Certificate of Origin

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
have the right to submit it under the open source license
indicated in the file; or

(b) The contribution is based upon previous work that, to the best
of my knowledge, is covered under an appropriate open source
license and I have the right under that license to submit that
work with modifications, whether created in whole or in part
by me, under the same open source license (unless I am
permitted to submit under a different license), as indicated
in the file; or

(c) The contribution was provided directly to me by some other
person who certified (a), (b) or (c) and I have not modified
it.

(d) I understand and agree that this project and the contribution
are public and that a record of the contribution (including all
personal information I submit with it, including my sign-off) is
maintained indefinitely and may be redistributed consistent with
this project or the open source license(s) involved.
