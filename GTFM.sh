#!/bin/bash

NAME="GTFM"
VERSION="0.001"
AUTHOR="budRich"
CONTACT='robstenklippa@gmail.com'
CREATED="2018-08-09"
UPDATED="2018-08-09"

THIS_DIR="$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )"
: "${GTFM_CONFIG:="${THIS_DIR}/doclist.ini"}"

main(){
  declare -A wikis
  declare -a wiki_index

  parseconfig

  : "${GTFM_SOURCE_DIR:="${wikis[general-source-dir]:-${PWD}/src}"}"
  : "${GTFM_TARGET_DIR:="${wikis[general-target-dir]:-${PWD}/trg}"}"

  while getopts :vhl option; do
    case "${option}" in
      l) printf '%s\n' "${wiki_index[@]}" ; exit ;;
      v) printf '%s\n' \
           "$NAME - version: $VERSION" \
           "updated: $UPDATED by $AUTHOR"
         exit ;;
      h|*) printinfo && exit ;;

    esac
  done

  mkdir -p "${GTFM_SOURCE_DIR}"
  getdox "$1"
}

parseconfig(){
  eval "$(awk -F'=' '/./ && /^[^#]/ {
    if (/^[[]/) {
      gsub(/[]]|[[]/,"",$0)
      cs=$0
      if (cs!="general")
        print "wiki_index+=(" cs ")"
    } else if (/^[$]/) {
      sub("[$]","",$1)
      vars[$1]=$2
    } else {
      for (v in vars) { gsub("[$]"v,vars[v],$2) }
      print "wikis[" cs "-" $1 "]=" $2
    }
  }' "${GTFM_CONFIG}")"
}

getdox(){
  local u

  [[ -n $1 ]] && wiki_index=("$1")

  for w in "${wiki_index[@]}"; do
    u="${wikis[${w}-url]}"
    if [[ -z $u ]]; then
      ERR "no url for $w"
      continue
    elif [[ $u =~ [.]git$ ]]; then
      gitdown "$w"
    else
      webdown "$w"
    fi
  done
}

webdown(){
  local w u h t bd dd td
  w="$1"
  u="${wikis[${w}-url]}"
  t="${wikis[${w}-trim-top]}"
  h="${wikis[${w}-trim-bot]}"

  bd="${GTFM_SOURCE_DIR}/$w"
  dd="${u#*//}"
  td="${wikis[$w-target-dir]:-${GTFM_TARGET_DIR}}/$w"

  [[ $dd =~ [/]$ ]] && dd=${dd%/}

  opts=()

  [[ -n $h ]] && opts+=("|" head "-n" "-${h}")
  [[ -n $t ]] && opts+=("|" tail "+${t}")

  # wget -mkEpnp -l1 --no-parent

  [[ -d "${bd}" ]] || (
    mkdir -p "${bd}" 
    cd "${bd}" || exit 1
    wget -mkEpnp -l1 --no-parent "$u"
    mv "${dd}"/* .
    rm -rf "${dd%%/*}" "index.html"
  )

  mkdir -p "${td}"

  for f in "${bd}"/*.html ; do
    fname="${f##*/}" fname="${fname%.*}"
    cmd="html2text --ignore-images --ignore-links ${f}"
    ((${#opts[@]}>0)) \
      && cmd+="$(printf ' %s' "${opts[@]}")"
    eval "${cmd}" > "${td}/${fname}.md"
  done

}

gitdown(){

  # $1 (w) wikiname

  local g d w bd td
  w="${1}" # name of wiki
  d="${wikis[${w}-dir]}" # subdirectory with docs
  g="${wikis[${w}-url]}" # git url
  bd="${GTFM_SOURCE_DIR}/$w${d:+/}${d}" # base dir for downloaded docs
  td="${wikis[$w-target-dir]:-${GTFM_TARGET_DIR}}/$w"

  # printf 'w: %s\nu: %s\nd: %s\ng: %s\n\n' "$w" "$u" "$d" "$g"

  # if local repo exist in $GTFM_SOURCE_DIR, pull latest
  # otherwise create repo and pull (d)
  if [[ -d "${GTFM_SOURCE_DIR}/${w}/.git" ]]; then
  (
    cd "${GTFM_SOURCE_DIR}/${w}" || exit 1
    git pull --depth=1 origin "${wikis[${w}-branch]:-master}"
  )
  else
  (
    cd "${GTFM_SOURCE_DIR}" || exit 1
    git init "$w"
    cd "$w" || exit
    git remote add origin "$g"
    [[ -n ${d} ]] && {
      git config core.sparsecheckout true
      echo "${d}/*" >> .git/info/sparse-checkout
    }
    git pull --depth=1 origin "${wikis[${w}-branch]:-master}"
  )
  fi

  # copy all files with target extension to $GTFM_TARGET_DIR
  eval "$(crawldocs "${bd}" "${wikis[${w}-ext]:-md}" \
    | awk -v wdir="${td}" -v base="${bd}" '{
    full=$0
    sub(base"/","",$0)
    fil=$0
    sub(/\/.*$/,"",$0)
    dir=$0
    if (fil==dir) {dir=""}
    print "mkdir -p " wdir "/" dir
    print "cp -f " full " " wdir "/" dir
  }')"
}

crawldocs(){
  local ext=$2

  for f in "${1}/"*; do
    [[ -d $f ]] && crawldocs "$f" "$ext" && continue
    [[ ${f##*.} = "${ext}" ]] || continue
    echo "$f"
  done
}

printinfo(){
about='`GTFM` - get the *fine* manual   

SYNOPSIS
--------

`GTFM` [`-v`|`-h`|`-l`]  
`GTFM` WIKI  

DESCRIPTION
-----------

Download documentation from git and the web for
offline reading.  

If `GTFM` is executed without any commandline options,
all wikis defined in `GTFM_CONFIG`, will get updated
or downloaded and copied to `GTFM_TARGET_DIR`.  

If a name of a WIKI is the last argument to `GTFM`,
only that WIKI will  get updated or downloaded and 
copied to `GTFM_TARGET_DIR`.  

See the default `GTFM_CONFIG` (*doclist.ini*) for
availbe configuration. 

OPTIONS
-------

`-v`  
Show version and exit.

`-h`  
Show help and exit.

`-l`  
Prints a list of all wikis defined in `GTFM_CONFIG`.

ENVIRONMENT
-----------
GTFM_CONFIG defaults to *$THIS_DIR/doclist.ini*  
configuration file always read by the script.

GTFM_TARGET_DIR defaults to *$PWD/trg*  
General target directory where to store documentation.
Can either be set with a ENVIRONMENT_VARIALBE or in
`GTFM_CONFIG`. It is possible to specify different 
target direcories for different wikis in `GTFM_CONFIG`.  

GTFM_SOURCE_DIR defaults to *$PWD/src*  
General directory where to download documentation
source. Can either be set with a ENVIRONMENT_VARIALBE 
or in `GTFM_CONFIG`.  

DEPENDENCIES
------------

html2text  
git  
'

bouthead="
${NAME^^} 1 ${CREATED} Linux \"User Manuals\"
=======================================

NAME
----
"

boutfoot="
AUTHOR
------

${AUTHOR} <${CONTACT}>
<https://budrich.github.io>

SEE ALSO
--------

git(1), html2text(1)
"


  case "$1" in
    m ) printf '%s' "# ${about}" ;;
    
    f ) 
      printf '%s' "${bouthead}"
      printf '%s' "${about}"
      printf '%s' "${boutfoot}"
    ;;

    ''|* ) 
      printf '%s' "${about}" | awk '
         BEGIN{ind=0}
         $0~/^```/{
           if(ind!="1"){ind="1"}
           else{ind="0"}
           print ""
         }
         $0!~/^```/{
           gsub("[`*]","",$0)
           if(ind=="1"){$0="   " $0}
           print $0
         }
       '
    ;;
  esac
}

ERR(){ >&2 echo "[WARNING]" "${@}"; }
ERX(){ >&2 echo "[ERROR]" "${@}"  ; exit 1 ; }

if [ "$1" = "md" ]; then
  printinfo m
  exit
elif [ "$1" = "man" ]; then
  printinfo f
  exit
else
  main "${@}"
fi
