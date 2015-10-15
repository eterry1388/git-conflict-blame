# Git Conflict Blame

Git command that shows the blame on the lines that are in conflict. This should be ran
after a `git merge` command has been ran and there are files that are in conflict.

## Installation

```bash
gem install git-conflict-blame
```

This gem depends on [Rugged](http://www.rubydoc.info/gems/rugged), which requires
certain dependencies installed.  Make sure you have `cmake` installed on your system.

If you get an error like this:

```
ERROR:  Error installing git-conflict-blame:
ERROR: Failed to build gem native extension.
checking for gmake... no
checking for make... yes
checking for cmake... no
ERROR: CMake is required to build Rugged.
*** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.
```

Try running this (if you are on a Debian-based OS):

```bash
sudo apt-get install cmake
```

## Usage

Run this inside a directory of your git repository. If there are no conflicts,
nothing will be displayed.

To output in a colorized pretty format:

```bash
git conflict-blame
```

To output machine-readable data:

```bash
git conflict-blame --json
```

To output pretty machine-readable data:

```bash
git conflict-blame --json --pretty
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eterry1388/git-conflict-blame.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
