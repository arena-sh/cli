#!/bin/bash

API_ENDPOINT="https://arena.sh"

if ! [ -x "$(command -v curl)" ]; then
    echo 'Error: curl is not installed.' >&2
    exit 1
fi

if ! [ -x "$(command -v python)" ]; then
    echo 'Error: python is not installed.' >&2
    exit 1
fi

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

OS="n/a"
case "$(uname -s)" in
   Darwin) OS="macosx" ;;
   Linux) OS="linux" ;;
   CYGWIN*|MINGW32*|MSYS*) OS="windows" ;;
esac

query=""
current_page="1"
total_pages="1"
fetch_results() {
    page=$1
    shift
    query="${@}"

    if (( page < 1  )); then
        page="1"
    fi
    if (( page > total_pages )); then
        page="$total_pages"
    fi

    response=$(curl -fGs "$API_ENDPOINT/cli/search/" --data-urlencode "q=$query" --data-urlencode "p=$page")
    if [ -z "$response" ]
    then
        echo "Missing input or server is unavailable."
        exit 1
    fi
    results=$(echo "$response" | python -c "import sys, json; print(json.load(sys.stdin)['results'])")
    total_pages=$(echo "$response" | python -c "import sys, json; print(json.load(sys.stdin)['total_pages'])")
    current_page=$(echo "$response" | python -c "import sys, json; print(json.load(sys.stdin)['current_page'])")
    if [ -z "$results" ]
    then
        echo "No results found."
        exit 0
    fi
}
fetch_results 1 ${@}

view_results() {
 clear
 echo -e "\033[1;32m[Search results for $query]\033[0m"
 echo -e "\033[1mKey\tGame\tType\tPlayers\tLoc\tName\033[0m"
 COUNTER=1
 echo "$results" | while IFS= read -r line ; do echo -e "${COUNTER}\t${line}" | sed -E "s/(.*);#;.*/\1/";COUNTER=$[$COUNTER +1]; done
 echo -e "page: $current_page/$total_pages\n"
 echo -ne "p = prev, n = next, q = quit"
 echo -ne "\n$1"
 while read -n1 -r -p "choose a server by using a number key" && [[ $REPLY != q && $REPLY != " " ]]; do
   case $REPLY in
     p) clear;fetch_results $[$current_page-1] $query; view_results;break;;
     n) clear;fetch_results $[$current_page+1] $query; view_results;break;;
   esac
   clear
   viewdetails $REPLY
   break
 done
}

viewdetails() {
   ORDER=$1
   game_id=$(echo "$results" | sed -n "${ORDER}p" | sed -E "s/.*;#;(.*)/\1/")

   if [ -z "$game_id" ]
   then
      view_results "unknown game, please choose an existing line\n"
   else
      clear
      game_info=$(curl -Gs "$API_ENDPOINT/cli/game/$game_id/" --data-urlencode "os=$OS")
      chart=$(echo $game_info | python -c "import sys, json; print(json.load(sys.stdin)['chart'])")
      game_cmd=$(echo $game_info | python -c "import sys, json; print(json.load(sys.stdin)['cmd'])")
      echo -ne "\033[1;32m[Server information]\033[0m\n"
      echo -ne "$chart"
      echo -ne "\n\n"
      echo -ne "\033[1;32m[Command to launch and join]\033[0m\n"
      if [ -z "$game_cmd" ]
      then
          echo -ne "Currently unavailable for your platform, but we're working hard to bring the support!"
      else
          echo -ne "$game_cmd"
      fi
      echo -ne "\n\n"
      while read -n1 -r -p "r = run, v = web, b = back, q = quit" && [[ $REPLY != q && $REPLY != " " ]]; do
        echo -ne "\n"
        case $REPLY in
         b) clear;view_results;break;;
         v)
             url_exec="python -mwebbrowser"
             if [ "$OS" = "windows" ]; then
                 url_exec="cygstart"
             fi
             eval "$url_exec '$API_ENDPOINT/game/$game_id/'";continue;;
         r)
           cmd_to_run="$game_cmd"
           #cmd_to_run="echo 'No such file'" #testing purposes only, this should still act like game exists as we only capture stderr below
           if [ "$OS" = "windows" ]; then
               echo "$game_cmd" > cmd.ps1
               cmd_to_run="powershell -executionpolicy bypass -file cmd.ps1"
           fi
           { run_stderr=$(eval $cmd_to_run 2>&1 >&3 3>&-); } 3>&1
           not_found=$(echo "$run_stderr" | head -n1 | grep -av "shared lib" | grep -a "No such file\|cannot be run" | tr -d '\040\011\012\015')
           if [ -z "$not_found" ] 
           then
               echo -ne "$run_stderr"
           else
               echo "Game not found, checking for an unified zip..."
               game_code=$(echo "$game_info" | python -c "import json,sys;obj=json.load(sys.stdin); print obj['game_code']")
               dl_info=$(curl -Gs "$API_ENDPOINT/cli/game-dl/$game_code/" --data-urlencode "os=$OS")
               dl_link=$(echo $dl_info | python -c "import sys, json; print(json.load(sys.stdin)['dl_link'])")
               dl_notes=$(echo $dl_info | python -c "import sys, json; print(json.load(sys.stdin)['after_install'])")
               if [ -z "$dl_link" ] 
               then
                   echo "Unified zip unavailable, please follow installation instructions at the server page (press v to open)" 
               else
                 read -n1 -r -p "Continue to download and install? [Y/n]";
                 case $REPLY in
                     Y) echo -ne "\nDownloading $dl_link..\n"
                         if ! [ -x "$(command -v unzip)" ]; then
                             echo 'Error: unzip is not installed. Please install it first so we can extract the zip file after the download.' >&2
                             exit 1
                         fi
                         tmpdir=$(dirname $(mktemp -u))
                         curl $dl_link -J -L -o $tmpdir/gamefiles.zip
                         #cp ~/gamefiles.zip $tmpdir/  #keep for local dev testing
                         dest=$HOME/games/
                         if [ "$OS" = "macosx" ]; then
                             dest=/Applications/games/
                         elif [ "$OS" = "windows" ]; then
                             dest="/cygdrive/C/games/"
                         fi
                         mkdir -p $dest
                         unzip $tmpdir/gamefiles.zip -d $dest
                         chmod -R 777 $dest
                         echo -ne "\n\nInstalled to $dest\n"
                         if ! [ -z "$dl_notes" ]; then
                             echo -ne "\n$dl_notes\n"
                             exit 0
                         else
                             continue
                         fi
                         echo -ne "\n"
                         continue
                     ;;
                     *) echo -ne "\n"
                 esac
               fi
           fi
         ;;
        esac
        echo -ne "\n"
      done
   fi

}

view_results

echo -e "\n"
