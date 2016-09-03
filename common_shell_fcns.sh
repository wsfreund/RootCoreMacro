find_lib()
{
  array=$(echo $LD_LIBRARY_PATH | tr ':' ' ' )
  OLD_IFS=$IFS; IFS=' ';
  for place in $array; do
    #echo "Searching on $place" >&2 
    if test -n "$(find $place -mindepth 1 -maxdepth 1 -name "$1*" 2>/dev/null)"; then
      IFS=$OLD_IFS
      echo "${place}"
      return 0;
    fi
  done
  IFS=$OLD_IFS
  return 1;
}

add_to_env_file()
{
  # Default values
  only_set=0
  var=""
  value=""
  while :; do
    case $1 in
      --only-set)
        only_set=1
        ;;
      --)              # End of all options.
        shift
        break
        ;;
      -?*)
        echo 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;
      *)               # Default case: If no more options then break out of the loop.
        if test "x$1" != "x"; then
          if test "x$var" = "x"; then
            var="$1"
          elif test "x$value" = "x"; then
            value="$1"
          else
            echo 'WARN: Did not know what to do with argument (ignored): %s\n' "$1" >&2
          fi
        else
          break
        fi
    esac
    shift
  done
  if test "$only_set" -eq "0"; then
    echo "test \$(echo \":\$$var:\" | grep -q \":$value:\"; echo \$?) -ne 0 && export \"$var\"=\"$value:\$$var\" || true" >> $NEW_ENV_FILE
  else
    echo "export \"$var\"=\"$value\"" >> $NEW_ENV_FILE
  fi
}

add_to_env()
{
  var=$1
  add_path=$2
  test $(echo ":$(eval echo \$$var):" | grep -q ":$add_path:"; echo $?) -ne 0 && export "$var=$add_path:$(eval echo \$$var)" || true
}

check_openmp()
{
  if test "$(root-config --cc)" != "clang"; then
    file=$(mktemp)
    echo "int main(){return 0;}" > "${file}.cxx"
    output=$(mktemp)
    $CXX -fopenmp "${file}.cxx" -o $output; ret=$?
    test -e $file && rm $file
    test -e $output && rm $output
    rm "${file}.cxx"
    return $ret
  else
    echo "WARN: root was compiled with clang, no multi-processing available."
    return 1;
  fi
}
