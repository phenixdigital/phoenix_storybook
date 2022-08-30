# PhxLiveStorybook contributing guide

Please take a moment to review this document in order to make the contribution process easy and effective for everyone involved!

## Using the issue tracker

Use the issues tracker for:

- [Bug reports](#bug-reports)
- [Submitting pull requests](#contributing-code)
- Feature requests

## Bug Reports

A bug is either a _demonstrable problem_ that is caused by the code in the repository, or indicate missing, unclear, or misleading documentation. Good bug reports are extremely helpful - thank you!

Guidelines for bug reports:

1. **Use the GitHub issue search** &mdash; check if the issue has already been
   reported.

2. **Check if the issue has been fixed** &mdash; try to reproduce it using the
   `master` branch in the repository.

3. **Isolate and report the problem** &mdash; ideally create a reduced test
   case.

Please try to be as detailed as possible in your report. Please provide steps to reproduce the issue as well as the outcome you were expecting! All these details will help developers to fix any potential bugs.

## Contributing documentation

Code documentation (`@doc`, `@moduledoc`, `@typedoc`) has a special convention:
the first paragraph is considered to be a short summary.

For functions, macros and callbacks say what it will do. For example write
something like:

```elixir
@doc """
Marks the given value as HTML safe.
"""
def safe({:safe, value}), do: {:safe, value}
```

For modules, protocols and types say what it is. For example write
something like:

```elixir
defmodule PhxLiveStorybook.Foo do
  @moduledoc """
  Conveniences for working on Foo.
  ...
  """
```

Keep in mind that the first paragraph might show up in a summary somewhere, long
texts in the first paragraph create very ugly summaries. As a rule of thumb
anything longer than 80 characters is too long.

Try to keep unnecessary details out of the first paragraph, it's only there to
give a user a quick idea of what the documented "thing" does/is. The rest of the
documentation string can contain the details, for example when a value and when
`nil` is returned.

If possible include examples, preferably in a form that works with doctests.
This makes it easy to test the examples so that they don't go stale and examples
are often a great help in explaining what a function does.

## Contributing code

Good pull requests - patches, improvements, new features - are a fantastic
help. They should remain focused in scope and avoid containing unrelated
commits.

**IMPORTANT**: By submitting a patch, you agree that your work will be
licensed under the license used by the project.

If you have any large pull request in mind (e.g. implementing features,
refactoring code, etc), **please ask first** otherwise you risk spending
a lot of time working on something that the project's developers might
not want to merge into the project.

Please adhere to the coding conventions in the project (indentation,
accurate comments, etc.) and don't forget to add your own tests and
documentation. When working with git, we recommend the following process
in order to craft an excellent pull request

### Setup your git

1. [Fork](https://help.github.com/articles/fork-a-repo/) the project, clone your fork, and configure the remotes:

```bash
# Clone your fork of the repo into the current directory
git clone https://github.com/<your-username>/phx_live_storybook
# Navigate to the newly cloned directory
cd phx_live_storybook
# Assign the original repo to a remote called "upstream"
git remote add upstream https://github.com/phenixdigital/phx_live_storybook
```

2. If you cloned a while ago, get the latest changes from upstream, and update your fork:

```bash
git checkout main
git pull upstream main
git push
```

3. Clone phx_live_storybook_sample alongside this repository.

```bash
cd ..
git clone git@github.com:phenixdigital/phx_live_storybook_sample.git
```

And follow [phx_live_storybook_sample README.md](https://github.com/phenixdigital/phx_live_storybook_sample) instructions.

4. Create a new feature branch (off of `main`) to contain your feature, change, or fix.

**IMPORTANT**: Making changes in `main` is discouraged. You should always keep your local `main` in sync with upstream `main` and make your changes in feature branches.

```bash
git checkout -b <feature-branch-name>
```

5. Commit your changes in logical chunks. Keep your commit messages organized, with a short description in the first line and more detailed information on the following lines. Feel free to use Git's [interactive rebase](https://help.github.com/articles/about-git-rebase/) feature to tidy up your commits before making them public.

6. Make sure all the tests are still passing.

```bash
mix test
```

7. Make sure the code you wrote is covered by tests

```bash
mix coverage
```

8. Make sure your code is formatted

```bash
mix format
```

9. Make sure your code is following code standards

```bash
mix credo
```

10. [Open a Pull Request](https://help.github.com/articles/about-pull-requests/) with a clear title and description.

11. If you haven't updated your pull request for a while, you should consider rebasing on main and resolving any conflicts.

**IMPORTANT**: _Never ever_ merge upstream `main` into your branches. You should always `git rebase` on `main` to bring your changes up to date when necessary.

```bash
git checkout main
git pull upstream main
git checkout <your-feature-branch>
git rebase main
```

Thank you for your contributions!
