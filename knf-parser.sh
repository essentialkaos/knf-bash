#!/bin/bash

## KNF PARSER ##################################################################

# Reads configuration in KNF format and declare properties from it
#
# 1: Path to configuration file (String)
#
# Code: Yes
# Echo: No
parseKNF() {
  local knf="${1//\~/$HOME}"
  local knf_app knf_line knf_sec knf_prop knf_val knf_macro

  if [[ ! -r "$knf" ]] ; then
    echo "File $knf is not exist or not readable" 1>&2
    return 1
  fi

  for knf_app in "echo" "cut" "sed" "tr" "grep" ; do
    if ! type -P "$knf_app" &> /dev/null ; then
      echo "KNF parsing requires $knf_app utility" 1>&2
      return 1
    fi
  done

  while read knf_line ; do
    if [[ $knf_line =~ \[([a-zA-Z0-9_-]+)\] ]] ; then
      knf_sec="${BASH_REMATCH[1]}"
      continue
    fi

    if [[ $knf_line =~ ^[\ \t]*([a-zA-Z0-9_-]+): ]] ; then
      knf_prop="${BASH_REMATCH[1]//-/_}"
    else
      echo "File $knf is misformatted" 1>&2
      return 1
    fi

    knf_prop=$(echo "$knf_prop" | tr '[:upper:]' '[:lower:]')
    knf_val=$(echo "$knf_line" | cut -f2-99 -d':' | sed 's/^ *//g' | sed 's/^\t*//g' | sed 's/ *$//g')

    if [[ -z "$knf_val" || "$knf_val" == "false" ]] ; then
      continue
    fi

    while : ; do
      if [[ "$knf_val" =~ \{([a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+)\} ]] ; then
        knf_macro="${BASH_REMATCH[1]/:/_}"
        knf_val="${knf_val//${BASH_REMATCH[0]}/${!knf_macro}}"
      else
        break
      fi
    done

    declare -g "${knf_sec}_${knf_prop}"="$knf_val"

  done < <(grep -Pv '^[ ]*(#(?!\!)|[ ]*$)|false[ ]*$' "$knf")
}

################################################################################
