#!/bin/bash

projectsPath=projects.json
schemaPath=schema.json

#set -xe

_logMessage () {
  type=$1
  message=$2
  date=$(date -I'seconds')

  printf '%s [%s] %s\n' "$date" "$type" "$message"
}

_validate () {

  local fail=false

  if ! yajsv -q -s "$schemaPath" "$projectsPath" ; then
    _logMessage error "Invalid schema."
    fail=true
  fi
  
  for i in .name .path; do
    if ! jq --arg type $i -c '(unique_by($type)|length) as $unique | length == $unique' "$projectsPath" > /dev/null 2>&1 ; then
      _logMessage error "Name and Path must be unique."
      fail=true
    fi
  done
  
  while read -r name path; do

    _logMessage info "Validating project: $name ."

    if ! [ -d "$path" ] || ! [ -f "$path/terragrunt.hcl" ]; then
      _logMessage error "Project $name must contain terragrunt.hcl file."
      fail=true
    fi
  done < <(jq -r  '.[] | "" + .name + " " + .path + " " + .login' "$projectsPath")
  
  if $fail; then
    _logMessage error "Failed."
    exit 1
  else
    _logMessage info "Validation done."
    exit 0
  fi
}

_getCommitRange () {
  if [ -z "$CI_BUILD_BEFORE_SHA" ] || [ -z "$CI_COMMIT_SHA" ]; then
    _logMessage error "CI_COMMIT_SHA and CI_BUILD_BEFORE_SHA must be set."
    exit 1
  elif [ "$CI_BUILD_BEFORE_SHA" == "0000000000000000000000000000000000000000" ]; then
    range="HEAD"
  else
    range="$CI_BUILD_BEFORE_SHA...$CI_COMMIT_SHA"
  fi
}


_getProjectsToChange () {
  action=$1

  declare -a pnames
  declare -a ppaths
  declare -a pmethods

  if [ -n "$PROJECT" ]; then
    projects=( "$(jq -r  '.[].name' "$projectsPath")" )
    if [[ ! " ${projects[*]} " =~ $PROJECT ]]; then
      _logMessage error "Project not found: $PROJECT"
      exit 1
    else
      _logMessage info "Project: $PROJECT will be changed."

      ppath=$(jq --arg pname "$PROJECT" -r  '.[] |  select(.name == $pname ).path' "$projectsPath")
      pmethod=$(jq --arg pname "$PROJECT" -r  '.[] |  select(.name == $pname ).login' "$projectsPath")

      pnames+=( "$PROJECT" )
      ppaths+=( "$ppath" )
      pmethods+=( "$pmethod" )

    fi
  else
     while read -r pname ppath pmethod ; do
      if ! git diff --exit-code --quiet "$range" -- "$ppath"; then
      
        _logMessage info "Project: $pname will be changed."

        pnames+=( "$pname" )
        ppaths+=( "$ppath" )
        pmethods+=( "$pmethod" )
                
      fi
    done < <(jq -r  '.[] | "" + .name + " " + .path + " " + .login' "$projectsPath")
  fi

  if (( "${#pnames[@]}" > 0 )); then
   if [ "$action" == "validate" ]; then
      for i in ${#pnames[@]}; do
         TERRAGRUNT_DISABLE_INIT="true" terragrunt validate --terragrunt-working-dir "${ppaths[i]}"
      done
   elif [ "$action" == "plan" ]; then
     # TODO: loop over unique logins
     readarray -td '' umethods< <(printf '%s\0' "${pmethods[@]}" | LC_ALL=C sort -zu)
     for m in "${umethods[@]}"; do
      _cliLogin "$m"
     done
     for i in ${#pnames[@]}; do
        terragrunt plan --terragrunt-working-dir "${ppaths[i]}"
     done
     for m in "${umethods[@]}"; do
      _cliLogout "$m"
     done
   elif [ "$action" == "apply" ]; then
     readarray -td '' umethods< <(printf '%s\0' "${pmethods[@]}" | LC_ALL=C sort -zu)
     for m in "${umethods[@]}"; do
      _cliLogin "$m"
     done
     for i in ${#pnames[@]}; do
        terragrunt apply --auto-apply --terragrunt-working-dir "${ppaths[i]}"
     done
     for m in "${umethods[@]}"; do
      _cliLogout "$m"
     done
   elif [ "$action" == "destroy" ]; then
     readarray -td '' umethods< <(printf '%s\0' "${pmethods[@]}" | LC_ALL=C sort -zu)
     for m in "${umethods[@]}"; do
      _cliLogin "$m"
     done
     for i in ${#pnames[@]}; do
        terragrunt destroy --auto-apply --terragrunt-working-dir "${ppaths[i]}"
     done
     for m in "${umethods[@]}"; do
      _cliLogout "$m"
     done
   fi
  elif (( "${#pnames[@]}" == 0 )); then
   echo "no changes"
   exit 0
  fi

}


_cliLogin () {
  cloud=$1
  if [ "$cloud" == "azure" ]; then
    maxtimeout="900"
    regular="^To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code [A-Z0-9]{9} to authenticate."

    exec 3< <( timeout --preserve-status -k 1 "$maxtimeout" az login --use-device-code --output none 2>&1 ) ; pid=$!
    while IFS= read -r line <&3
    do
        if [[ $line =~ $regular ]]; then
            printf '%s' "$line"
            _logMessage info "Login invoked. Will timeout in $maxtimeout"
            wait $pid
        else
            _logMessage info "Unknown error. Hint: Check regex vs output"
            #break
            exit 1
        fi
    done
    _logMessage info "Logout from azure."
  elif [ "$cloud" == "aws" ]; then
    _logMessage info "todo aws."
    elif [ "$cloud" == "all" ]; then
      _logMessage info "Login to all."
  else
    _logMessage info "No need to login."
  fi
}



_cliLogout () {
  cloud=$1

  if [ "$cloud" == "azure" ]; then
    az logout || true
    _logMessage info "Logout from azure."
  elif [ "$cloud" == "aws" ]; then
    _logMessage info "Logout from aws."
  elif [ "$cloud" == "all" ]; then
    _logMessage info "Logout from all."
  else
    _logMessage info "No need to logout."
  fi
}



case  $MODE  in
      preflight)
          _validate
          ;;
      validate)
          _getCommitRange
          _getProjectsToChange validate
          ;;
      plan)
          _getCommitRange
          _getProjectsToChange plan
          ;;
      apply)
          _getCommitRange
          _getProjectsToChange apply
          ;;
      destroy)
          _getCommitRange
          _getProjectsToChange destroy
          ;;
      *)
          printf 'MODE variable must be one of [preflight, validate, plan, apply, destroy]'
          ;;
esac
