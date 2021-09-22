<p align="center"><a href="#readme"><img src="https://gh.kaos.st/knf-bash.svg"/></a></p>

<br/>

This repository contains a parser for [KNF files](https://kaos.sh/knf-spec) for use in bash scripts.

All properties from the KNF file after parsing will be defined as global variables with the next naming scheme: `section_property`. For example, property from section "http" with the name "ip" will be defined as variable `http_ip`.

If the property name contains one or more `-` symbols, all of them will be replaced by the symbol `_`. For example, property from section "http" with the name "port-range" will be defined as variable `http_port_range`.

All uppercase symbols will be transformed to lowercase. For example, property from section "HTTP" with the name "Port" will be defined as variable `http_port`.

### Usage example

```
[log]

  # Path to directory with logs
  dir: /var/log/myapp

  # Path to log file
  file: {log:dir}/myapp.log
```

```bash
#!/bin/bash

main() {
  local config="~/config.knf"

  if [[ -d "$log_dir" ]] ; then
    echo "Text for log" >> $log_file
  fi
}

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

main "$@"
```

### Contributing

Before contributing to this project please read our [Contributing Guidelines](https://github.com/essentialkaos/contributing-guidelines#contributing-guidelines).

### License

[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)

<p align="center"><a href="https://essentialkaos.com"><img src="https://gh.kaos.st/ekgh.svg"/></a></p>
