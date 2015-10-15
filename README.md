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

### To output in a colorized pretty format

#### Run this:

```bash
git conflict-blame
```

### To see this:

```
1 files in conflict found!
Parsing files to find out who is to blame...
app.rb
  00000000   not.committed.yet              2015-10-15    [7     ]  <<<<<<< HEAD
  ad3e1b25   eterry1388@aol.com             2015-10-15    [8     ]  output = add( 5, 6 
  ad3e1b25   eterry1388@aol.com             2015-10-15    [9     ]  puts output
  00000000   not.committed.yet              2015-10-15    [10    ]  =======
  b8fb28f1   eterry1388@aol.com             2015-10-15    [11    ]  puts add( 5, 6 
  00000000   not.committed.yet              2015-10-15    [12    ]  >>>>>>> master

README.md
  00000000   not.committed.yet              2015-10-15    [1     ]  <<<<<<< HEAD
  db0d9920   eterry1388@aol.com             2015-10-15    [2     ]  My totally awesome readme file!
  00000000   not.committed.yet              2015-10-15    [6     ]  =======
  2e9fcc79   eterry1388@aol.com             2015-10-15    [7     ]  My awesome readme file for everyone!
  00000000   not.committed.yet              2015-10-15    [10    ]  >>>>>>> master
```

### To output machine-readable data

#### Run this:

```bash
git conflict-blame --json
```

### To see this:

```json
{"exception":false,"count":1,"data":{"app.rb":[[{"commit_id":"00000000","email":"not.committed.yet","date":"2015-10-15","line_number":7,"line_content":"<<<<<<< HEAD"},{"commit_id":"ad3e1b25","email":"eterry1388@aol.com","date":"2015-10-15","line_number":8,"line_content":"output = add( 5, 6 "},{"commit_id":"ad3e1b25","email":"eterry1388@aol.com","date":"2015-10-15","line_number":9,"line_content":"puts output"},{"commit_id":"00000000","email":"not.committed.yet","date":"2015-10-15","line_number":10,"line_content":"======="},{"commit_id":"b8fb28f1","email":"eterry1388@aol.com","date":"2015-10-15","line_number":11,"line_content":"puts add( 5, 6 "},{"commit_id":"00000000","email":"not.committed.yet","date":"2015-10-15","line_number":12,"line_content":">>>>>>> master"}]]}}
```

### To output pretty machine-readable data

#### Run this:

```bash
git conflict-blame --json --pretty
```

### To see this:

```json
{
  "exception": false,
  "count": 1,
  "data": {
    "app.rb": [
      [
        {
          "commit_id": "00000000",
          "email": "not.committed.yet",
          "date": "2015-10-15",
          "line_number": 7,
          "line_content": "<<<<<<< HEAD"
        },
        {
          "commit_id": "ad3e1b25",
          "email": "eterry1388@aol.com",
          "date": "2015-10-15",
          "line_number": 8,
          "line_content": "output = add( 5, 6 "
        },
        {
          "commit_id": "ad3e1b25",
          "email": "eterry1388@aol.com",
          "date": "2015-10-15",
          "line_number": 9,
          "line_content": "puts output"
        },
        {
          "commit_id": "00000000",
          "email": "not.committed.yet",
          "date": "2015-10-15",
          "line_number": 10,
          "line_content": "======="
        },
        {
          "commit_id": "b8fb28f1",
          "email": "eterry1388@aol.com",
          "date": "2015-10-15",
          "line_number": 11,
          "line_content": "puts add( 5, 6 "
        },
        {
          "commit_id": "00000000",
          "email": "not.committed.yet",
          "date": "2015-10-15",
          "line_number": 12,
          "line_content": ">>>>>>> master"
        }
      ]
    ]
  }
}

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eterry1388/git-conflict-blame.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
