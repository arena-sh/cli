## arena.sh CLI

<img src="https://media.giphy.com/media/dyigcCeLILqfA6PqOV/giphy.gif" width="500">

A CLI browser for open-source arena shooter games.

## Platforms and Games
Tested to be working on MacOSX, Linux and Windows/Cygwin. For Cygwin, make sure to install all three packages below. 

When a game is not found, user will be asked to download the official unified zip wherever available and "after installation notes" specific to the platform will be shown (for e.g. you need to install OpenAL-soft on Linux or place its dll files on Windows). 

### Supported Games

Currently, following games are tested to be working on all platforms:

  - Open Arena (unified zip available)
  - Xonotic (unified zip available)
  - QuakeWorld
  - Alien Arena (osx support pending)


## How to Install

Requirements:

- curl
- python2 or later
- unzip (optional)

You can download the bash script as follows and start using:

```
$ curl https://raw.githubusercontent.com/arena-sh/cli/master/arena.sh -O
$ chmod +x arena.sh
```

## Quick Start

Here are valid examples with some of their short-forms:

```
$ ./arena.sh game:openarena type:ffa +humans
$ ./arena.sh defrag game:xonotic
$ ./arena.sh game:quakeworld type:duel +he +hf
$ ./arena.sh g:qw t:duel +he +hf       # short-form
$ ./arena.sh player:sarge
$ ./arena.sh p:sarge       # short-form
```

QuakeWorld duel spot demonstration:

<img src="https://media.giphy.com/media/lSa4BBIzGrbpAtoWcX/giphy.gif" width="450">

## Usage
Any string will search in server names and players. However, you can utilize filters and flags below to construct the search queries.

### Filters
| filter | short-form | description | examples
| ------ | ------ | ------ | ------|
| game: | g: | game title or short code | xonotic, xo, alienarena, aa, quakeworld, qw, openarena, oa |
| type: | t: | game type | ffa, ctf, duel, ca |
| map: | map: | game map | ztn, ztndm3, stormkeep |
| mod: | mod: | game mod | aftershock, rat, ktx, fortress |
| player: | p: | player name | metalbot, sarge |

### Conditions and Sorting
| name | description |
| ------ | ------ |
| +humans | have at least 1 human playing |
| +nearby | sort by nearby, default when +humans is applied |
| +he | hide empty |
| +hf | hide full |

## Auto Downloader (experimental)
If a launcher command fails to run, the official unified zip (for available games only) will be asked to be downloaded:

<img src="https://media.giphy.com/media/JQLxjOzAUgcB6O9M1I/giphy.gif" width="450">

Downloaded games will be unzipped at `$HOME` for Linux, `/Applications/games` at MacOSX and `C:\games` for Windows. 

It's good idea to pay attention for the "after installation" notes followed by the `unzip`. They are also accessible at any game/server web page as well (press v to open). 


## How Does It Compare to Qstat?
Qstat is a complete tool for querying server masters and querying each server afterwards. It can be considered as a full-scan solution. CLI tool provided here, use http://arena.sh/ as its backend so it doesn't hit any servers. In order to find the game you're looking for, all search is done within a single `curl` command from a readily populated list. Script itself only consist around 150 lines of bash, that means no compilation or installation is needed. Service approach also provides additional benefits of a powerful query language, rule set analysis and hiding of broken/fake servers. 


## Development & Reporting
When making a change, mind your best to keep the change compatible with all three platforms. If the problem is within the launcher command, please leave a <a href="https://arena.sh/feedback/">feedback</a> instead!

### Debugging
In case there is an unzip/run issue (even after applying installation notes presented at any server page at the game), to save bandwith, you can comment out the `curl` command and comment in `cp` operation at next line. Just make sure to grab gamefiles.zip and copy it to your home directory before losing the tmp location created by `mktemp`. 

