#! /bin/bash

###
#
# runMultiwfn.sh -- 
#   a wrapper script to establish an appropriate environment for Multiwfn 
# Copyright (C) 2019 Martin C Schwarzer
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
###

# Multiwfn initialization script
# See CHANGES.txt for more information
# and see VERSION for the current version information
#

# The following two lines give the location of the installation.
# They can be set in the rc file, too.
installpath_Multiwfn_gui="/path/is/not/set"
installpath_Multiwfn_nogui="/path/is/not/set"

# Set a default pdfviewer (needs to be an executable command found through PATH)
# Tested in that order are: "$use_pdfviewer" xdg-open gvfs-open evince okular less 
use_pdfviewer="xpdf"

# See the readme file for more details. 

#####
#
# The actual script begins here. 
# You might not want to make modifications here.
# If you do improve it, I would be happy to learn about it.
#

#
# Print some helping commands
# The lines are distributed throughout the script and grepped for
#

#hlp   This is $scriptname!
#hlp
#hlp   This script is a wrapper intended for Multiwfn $installpath_Multiwfn_gui (linux).
#hlp   A detailed description on how to install Multiwfn and/or
#hlp   manipulate this script is located in INSTALL.txt distributed 
#hlp   alongside this script.
#hlp
#hlp   runMultiwfn.sh  Copyright (C) 2019  Martin C Schwarzer
#hlp   This program comes with ABSOLUTELY NO WARRANTY; this is free software, 
#hlp   and you are welcome to redistribute it under certain conditions; 
#hlp   please see the license file distributed alongside this repository,
#hlp   which is available when you type '$scriptname license',
#hlp   or at <https://github.com/polyluxus/runMultiwfn.bash>.
#hlp
#hlp   VERSION    :   ${version:-undefined}
#hlp   DATE       :   ${versiondate:-undefined}
#hlp
#hlp   USAGE      :   $scriptname [options] [IPUT_FILE]
#hlp

helpme ()
{
    local line
    local pattern="^[[:space:]]*#hlp[[:space:]]?(.*)?$"
    while read -r line; do
      [[ "$line" =~ $pattern ]] && eval "echo \"${BASH_REMATCH[1]}\""
    done < <(grep "#hlp" "$0")
    exit 0
}

display_manual ()
{
    local manual_location use_Multiwfnpath pdf_open pdf_open_command
    use_Multiwfnpath=$(get_Multiwfnpath_or_exit "$installpath_Multiwfn_gui") || exit 1
    manual_location=$(find "$use_Multiwfnpath/" -iname 'Multiwfn*.pdf' -print -quit)
    debug "manual_location=$manual_location"
    if [[ -z $manual_location ]] ; then
      fatal "Unable to locate manual pdf."
    fi
    for pdf_open in "$use_pdfviewer" xdg-open gvfs-open evince okular less ; do
      debug "Testing: $pdf_open"
      pdf_open_command=$(command -v "$pdf_open") || continue
      "$pdf_open_command" "$manual_location" && exit 0
    done
    fatal "Could not find programm to open pdf; please check your settings."
}

#
# Print logging information and warnings nicely.
# If there is an unrecoverable error: display a message and exit.
#

message ()
{
    if (( stay_quiet <= 0 )) ; then
      echo "INFO   : " "$*" >&3
    else
      debug "(info   ) " "$*"
    fi
}

warning ()
{
    if (( stay_quiet <= 1 )) ; then
      echo "WARNING: " "$*" >&2
    else
      debug "(warning) " "$*"
    fi
    return 1
}

fatal ()
{
    if (( stay_quiet <= 2 )) ; then 
      echo "ERROR  : " "$*" >&2
    else
      debug "(error  ) " "$*"
    fi
    exit 1
}

debug ()
{
    echo "DEBUG  : " "$*" >&4
}    

# 
# Let's know where the script is and how it is actually called
#

get_absolute_location ()
{
#  Taken from https://stackoverflow.com/a/246128/3180795
  local resolve_file="$1" description="$2" 
  local link_target directory_name filename resolve_dir_name 
  debug "Getting directory for '$resolve_file'."
  #  resolve $resolve_file until it is no longer a symlink
  while [ -h "$resolve_file" ]; do 
    link_target="$(readlink "$resolve_file")"
    if [[ $link_target == /* ]]; then
      debug "File '$resolve_file' is an absolute symlink to '$link_target'"
      resolve_file="$link_target"
    else
      directory_name="$( dirname "$resolve_file" )" 
      debug "File '$resolve_file' is a relative symlink to '$link_target' (relative to '$directory_name')"
      #  If $resolve_file was a relative symlink, we need to resolve 
      #+ it relative to the path where the symlink file was located
      resolve_file="$directory_name/$link_target"
    fi
  done
  debug "File is '$resolve_file'" 
  filename="$( basename "$resolve_file" )"
  debug "File name is '$filename'"
  resolve_dir_name="$( dirname "$resolve_file")"
  directory_name="$( cd -P "$( dirname "$resolve_file" )" && pwd )"
  if [ "$directory_name" != "$resolve_dir_name" ]; then
    debug "$description '$directory_name' resolves to '$directory_name'"
  fi
  debug "$description is '$directory_name'"
  if [[ -z $directory_name ]] ; then
    echo "."
  else
    echo "$directory_name/$filename"
  fi
}

get_absolute_filename ()
{
  local resolve_file="$1" description="$2" return_filename
  return_filename=$(get_absolute_location "$resolve_file" "$description")
  return_filename=${return_filename##*/}
  echo "$return_filename"
}

get_absolute_dirname ()
{
  local resolve_file="$1" description="$2" return_dirname
  return_dirname=$(get_absolute_location "$resolve_file" "$description")
  return_dirname=${return_dirname%/*}
  echo "$return_dirname"
}


#
# Test if a given value is an integer
#

is_integer()
{
    [[ $1 =~ ^[[:digit:]]+$ ]]
}

validate_integer () 
{
    if ! is_integer "$1"; then
        [ -n "$2" ] && fatal "Value for $2 ($1) is no integer."
        [ -z "$2" ] && fatal "Value \"$1\" is no integer."
    fi
}

format_duration_or_exit ()
{
    local check_duration="$1"
    # Split time in HH:MM:SS
    # Strips away anything up to and including the rightmost colon
    # strips nothing if no colon present
    # and tests if the value is numeric
    # this is assigned to seconds
    local trunc_duration_seconds=${check_duration##*:}
    validate_integer "$trunc_duration_seconds" "seconds"
    # If successful value is stored for later assembly
    #
    # Check if the value is given in seconds
    # "${check_duration%:*}" strips shortest match ":*" from back
    # If no colon is present, the strings are identical
    if [[ ! "$check_duration" == "${check_duration%:*}" ]]; then
        # Strip seconds and colon
        check_duration="${check_duration%:*}"
        # Strips away anything up to and including the rightmost colon
        # this is assigned as minutes
        # and tests if the value is numeric
        local trunc_duration_minutes=${check_duration##*:}
        validate_integer "$trunc_duration_minutes" "minutes"
        # If successful value is stored for later assembly
        #
        # Check if value was given as MM:SS same procedure as above
        if [[ ! "$check_duration" == "${check_duration%:*}" ]]; then
            #Strip minutes and colon
            check_duration="${check_duration%:*}"
            # # Strips away anything up to and including the rightmost colon
            # this is assigned as hours
            # and tests if the value is numeric
            local trunc_duration_hours=${check_duration##*:}
            validate_integer "$trunc_duration_hours" "hours"
            # Check if value was given as HH:MM:SS if not, then exit
            if [[ ! "$check_duration" == "${check_duration%:*}" ]]; then
                fatal "Unrecognised duration format."
            fi
        fi
    fi

    # Modify the duration to have the format HH:MM:SS
    # disregarding the format of the user input
    # keep only 0-59 seconds stored, let rest overflow to minutes
    local final_duration_seconds=$((trunc_duration_seconds % 60))
    # Add any multiple of 60 seconds to the minutes given as input
    trunc_duration_minutes=$((trunc_duration_minutes + trunc_duration_seconds / 60))
    # save as minutes what cannot overflow as hours
    local final_duration_minutes=$((trunc_duration_minutes % 60))
    # add any multiple of 60 minutes to the hours given as input
    local final_duration_hours=$((trunc_duration_hours + trunc_duration_minutes / 60))

    # Format string and print it
    printf "%d:%02d:%02d" "$final_duration_hours" "$final_duration_minutes" \
                          "$final_duration_seconds"
}

#
# Get settings from configuration file
#

test_rc_file ()
{
  local test_runrc="$1"
  debug "Testing '$test_runrc' ..."
  if [[ -f "$test_runrc" && -r "$test_runrc" ]] ; then
    echo "$test_runrc"
    return 0
  else
    debug "... missing."
    return 1
  fi
}

get_rc ()
{
  local test_runrc_dir test_runrc_loc return_runrc_loc runrc_basename
  # The rc should have some similarity with the actual scriptname
  runrc_basename="$scriptbasename"
  while [[ -n $1 ]] ; do
    test_runrc_dir="$1"
    shift
    if test_runrc_loc="$(test_rc_file "$test_runrc_dir/.${runrc_basename}rc")" ; then
      return_runrc_loc="$test_runrc_loc" 
      debug "   (found) return_runrc_loc=$return_runrc_loc"
      continue
    elif test_runrc_loc="$(test_rc_file "$test_runrc_dir/${runrc_basename}.rc")" ; then 
      return_runrc_loc="$test_runrc_loc"
      debug "   (found) return_runrc_loc=$return_runrc_loc"
    fi
  done
  debug "(returned) return_runrc_loc=$return_runrc_loc"
  echo "$return_runrc_loc"
}

#
# Test, whether we can access the given file/directory
#

is_file ()
{
    [[ -f $1 ]]
}

is_readable ()
{
    [[ -r $1 ]]
}

is_readable_file_or_exit ()
{
    is_file "$1"     || fatal "Specified file '$1' is no file or does not exist."
    is_readable "$1" || fatal "Specified file '$1' is not readable."
}

# 
# Issue warning if options are ignored.
#

warn_additional_args ()
{
    while [[ -n $1 ]]; do
      warning "Specified option $1 will be ignored."
      shift
    done
}

#
# Determine or validate outputfiles
#

test_output_location ()
{
  local savesuffix=1 outputfile_return outputfile_return="$1"
  if ! is_file "$outputfile_return" ; then
    echo "$outputfile_return"
    debug "There is no outputfile '$outputfile_return'. Return 0."
    return 0
  else
    while is_file "${outputfile_return}.${savesuffix}" ; do
      (( savesuffix++ ))
      debug "The outputfile '${outputfile_return}.${savesuffix}' exists."
    done
    warning "Outputfile '$outputfile_return' exists."
    echo "${outputfile_return}.${savesuffix}"
      debug "There is no outputfile '${outputfile_return}.${savesuffix}'. Return 1."
    return 1
  fi
}

backup_file ()
{
  local move_message move_source="$1" move_target="$2"
  debug "Will attempt: mv -v $move_source $move_target"
  move_message="$(mv -v "$move_source" "$move_target" || fatal "Backup went wrong.")"
  message "File will be backed up."
  message "$move_message"
}

generate_outputfile_name ()
{
  local return_outfile_name="$1"
  if [[ -z "$return_outfile_name" ]] ; then
    debug "Nothing specified to base outputname on, will use '${scriptbasename}.out' instead."
    echo "${scriptbasename}.out"
  else
    debug "Will base outputname on '$return_outfile_name'."
    echo "${return_outfile_name%.*}.${scriptbasename}.out"
    debug "${return_outfile_name%.*}.${scriptbasename}.out"
  fi
}

#
# Check if logging was activated or deactivated
#

set_outputfile ()
{
  local test_outputfile="$1" free_outputfile
  if [[ -z $test_outputfile ]] ; then 
    test_outputfile=$(generate_outputfile_name "$inputfile")
  fi

  case "$execmode" in

    default | remote) 
      if ! free_outputfile=$(test_output_location "$test_outputfile"; return $?) ; then
        backup_file "$test_outputfile" "$free_outputfile" 
      fi
      outputfile="$test_outputfile"
      ;;
    logging) 
      # If an outputfile is specified, assume that the user 
      # wants to overwrite existing ones. Issue warning nevertheless.
      if ! free_outputfile=$(test_output_location "$test_outputfile" || return $?) ; then
        warning "File '$test_outputfile' will be overwritten."
      fi
      ;;
    nolog) 
      message "Logging is disabled." 
      unset outputfile
      ;;
    *) 
      fatal "Unknown execution mode (appeared in 'set_outputfile')." 
      ;;

  esac
}

#
# Assign the values from or to environment variables
#

check_environment_memory ()
{
    local test_memory="$1"
    if [[ "$forceScriptValues" == "true" ]] ; then
      debug "Forcefully setting KMP_STACKSIZE to $test_memory."
      echo "$test_memory"
      return
    fi
  
    if [[ -n $KMP_STACKSIZE ]] ; then
      debug "KMP_STACKSIZE has been set through the environment to $KMP_STACKSIZE."
      if (( test_memory > KMP_STACKSIZE )) ; then
        debug "KMP_STACKSIZE: $KMP_STACKSIZE; Requested: $test_memory."
        fatal "Requested memory is larger than set through environment."
      else
        debug "Adjusting memory to environment setting."
        test_memory="$KMP_STACKSIZE"
      fi
    else
      debug "KMP_STACKSIZE needs to be set."
    fi
      
    echo "$test_memory"
}

exit_if_Multiwfn_cmd_found ()
{
    local command_check command_check_out
    for command_check in Multiwfn multiwfn; do
      if command_check_out=$(command -v "$command_check" && return $?) ; then
        fatal "Found confusing executable in '$command_check_out'"
      fi
    done
}

remove_from_PATH ()
{ 
  local removefrompath="$1"
  debug "This is PATH: $PATH"
  debug "This will be removed: $removefrompath"
  PATH="${PATH/$removefrompath/}"
  debug "This is PATH now: $PATH"
}

warn_if_Multiwfnpath_set ()
{
    if [[ -n $Multiwfnpath ]] ; then
      warning "Multiwfnpath is set to '$Multiwfnpath'; this will be overwritten."
      unset Multiwfnpath
      debug "Unsetting Multiwfnpath."
    fi
}

check_Multiwfn_install ()
{
    local test_path="$1"
    debug "check_Multiwfn_install: test_path=$test_path"
    if [[ ! -d "$test_path" ]] ; then
      fatal "Cannot find Multiwfn installation path '$test_path'."
    fi
    if [[ ! -x "$test_path/Multiwfn" ]] ; then
      fatal "Multiwfn ($test_path/Multiwfn) does not exist or is not executable."
    fi
    echo "$test_path"
    debug "Path tested: $test_path"
}

get_Multiwfnpath_or_exit ()
{
    local test_path="$1" return_path
    exit_if_Multiwfn_cmd_found
    warn_if_Multiwfnpath_set
    # Check if there could be clashes if an executeable has been set 
    # via the environment
    local pattern="(^|:)([^:]*/[Mm]ulti[Ww][Ff][Nn]/[^:]*)(:|$)"
    local storepath
    if [[ "$PATH" =~ $pattern ]]; then
      warning "Found Multiwfn already in PATH: '${BASH_REMATCH[2]}'"
      storepath="${BASH_REMATCH[2]}"
      if [[ "$forceScriptValues" == "true" ]] ; then
        # Reminder: ${BASH_REMATCH[0]} is the full match
        # Store that value, in case it needs to be removed
        if [[ ${BASH_REMATCH[1]} == "${BASH_REMATCH[3]}" ]] ; then
          remove_from_PATH "${BASH_REMATCH[2]}:"
        else
          remove_from_PATH "${BASH_REMATCH[0]}"
        fi
        return_path=""
      else
        return_path="$storepath"
      fi
    fi
    if [[ -z $return_path ]] ; then
      return_path=$(check_Multiwfn_install "$test_path") || exit 1
    elif [[ "$return_path" == "$test_path" ]] ; then
      return_path=$(check_Multiwfn_install "$test_path") || exit 1
    else
      fatal "Found path '$return_path' does not match specified path '$test_path'."
    fi
    echo "$return_path"
}

replace_line ()
{
    debug "Enter 'replace_line'."
    local search_pattern="$1"
    debug "search_pattern=$search_pattern"
    local replace_pattern="$2"
    debug "replace_pattern=$replace_pattern"
    local inputstring="$3"
    debug "inputstring=$inputstring"

    (( $# < 3 )) && fatal "Wrong internal call of replace function. Please report this bug."

    if [[ "$inputstring" =~ ^(.*)($search_pattern)(.+)$ ]] ; then
      debug "Found match: ${BASH_REMATCH[0]}"
      echo "${BASH_REMATCH[1]}$replace_pattern${BASH_REMATCH[3]}"
      debug "Leave 'replace_line' with 0."
      return 0
    else
      debug "No match found. Leave 'replace_line' with 1."
      return 1
    fi
}    

modify_settingsini ()
{
    local settingsini_source_loc="$1" # settingsini_target_loc="$2"
    local -a settingsini_source_content
    local element
    mapfile -t settingsini_source_content < "$settingsini_source_loc"
    for element in "${settingsini_source_content[@]}" ; do
      replace_line "nthreads=[[:space:]]*[[:digit:]]+" "nthreads= $requested_numCPU" "${element}" && continue
      echo "${element}" 
    done
}

write_temp_settingsini ()
{
    local settingsini_source_loc settingsini_target_loc="$PWD/settings.ini"
    # Issue a warning if a local file has been found
    if [[ -e $PWD/settings.ini ]] ; then
      message "Found local 'settings.ini' and will modify it."
        backup_file "$PWD/settings.ini" "$PWD/settings.ini.bak" 
      settingsini_source_loc="$PWD/settings.ini.bak"
      settingsini_nocleanup="true"
    elif [[ -e "$scriptpath/settings.ini" ]] ; then 
      settingsini_source_loc="$scriptpath/settings.ini"
      message "Use template '$settingsini_source_loc' to pass on settings."
    elif [[ -e "$use_Multiwfnpath/settings.ini" ]] ; then 
      settingsini_source_loc="$use_Multiwfnpath/settings.ini"
      message "Use template '$settingsini_source_loc' to pass on settings."
    else
      warning "Cannot find suitable template for 'settings.ini'."
      warning "Be aware that Multiwfn might only run with default settings."
      return 1
    fi
    echo "// This file was created by '$scriptname'" > "$settingsini_target_loc"
    echo "// from the template '$settingsini_source_loc'" >> "$settingsini_target_loc"
    modify_settingsini "$settingsini_source_loc" >> "$settingsini_target_loc"
}

remove_temp_settingsini ()
{
    [[ $settingsini_nocleanup =~ [Tt][Rr][Uu][Ee]? ]] && return 0
    local remove_message
    if [[ -e $PWD/settings.ini ]] ; then
      remove_message=$(rm -v "$PWD/settings.ini")
      message "$remove_message"
    fi
}

#
# Process Options
#

process_options ()
{
    #hlp   OPTIONS    :
    #hlp    
    local OPTIND=1 

    while getopts :m:p:w:gRl:i:o:c:qfkQ:P:shH options ; do
        case $options in

          #hlp     -m <ARG> Define memory to be used per thread in byte.
          #hlp                (KMP_STACKSIZE; Default: 64000000)
          #hlp                [Option has no effect if set though environment.]
          #hlp
            m) 
               [[ -z $requested_KMP_STACKSIZE ]] || warning "Overwriting previously set memory of '$requested_KMP_STACKSIZE'."
               validate_integer "$OPTARG" "the memory"
               if (( OPTARG == 0 )) ; then
                 fatal "KMP_STACKSIZE must not be zero."
               fi
               requested_KMP_STACKSIZE="$OPTARG" 
               ;;

          #hlp     -p <ARG> Define number of threads to be used.
          #hlp                (Default: 2)
          #hlp                [Option has no effect if set though environment.]
          #hlp
            p) 
               validate_integer "$OPTARG" "the number of threads"
               if (( OPTARG == 0 )) ; then
                 fatal "Number of threads must not be zero."
               fi
               requested_numCPU="$OPTARG" 
               ;;

          #hlp     -w <ARG> Define maximum walltime. Format: [[HH:]MM:]SS
          #hlp                (Default: $requested_walltime)
          #hlp
            w) requested_walltime=$(format_duration_or_exit "$OPTARG")
               ;;

          #hlp     -g       run without GUI
          #hlp
            g) 
               request_gui_version="no"
               message "Running without GUI."
               if [[ -z $installpath_Multiwfn_nogui ]] ; then
                 fatal "There is no version set for running without GUI."
               fi
               ;;

          #hlp     -R       Execute in remote mode.
          #hlp              This option creates a job submission script for PBS
          #hlp              instead of running MultiWFN.
          #hlp
            R)
               case $execmode in
                 default) execmode="remote" ;;
                 logging) execmode="remote" ;;
                  remote) warning "Already operating in remote mode. Ignore '-R'." ;;
                   nolog) fatal "Options '-q' and '-R' are mutually exclusive." ;;
                       *) warning "Unspecified modus operandi. Ignore '-R'." ;;
               esac
               ;;

          #hlp     -l <ARG> Legacy mode (deprecated): Request different version.      
          #hlp              With version 0.5.0 of the script, this has been removed 
          #hlp              and no longer has any effect.
          #hlp
            l)
               fatal "Legacy mode has been removed in script version 0.5.0"
               ;;

          #hlp     -i <ARG> Specify file on which MultiWFN should operate.
          #hlp  
            i) 
               if [[ -z $inputfile ]] ; then
                 inputfile="$OPTARG" 
                 # If a filename is specified, it must exist, otherwise exit
                 is_readable_file_or_exit "$inputfile"
               else
                 fatal "I only know how to operate on one inputfile."
               fi 
               ;;

          #hlp     -c <ARG> Specify a file, that contains a sequence of 
          #hlp              numbers, that can be interpreted by MultiWFN.
          #hlp
            c) 
               if [[ -z $commandfile ]] ; then
                 commandfile="$OPTARG" 
                 # If a filename is specified, it must exist, otherwise exit
                 is_readable_file_or_exit "$commandfile"
               else 
                 fatal "I can only handle one set of commands."
               fi
               ;;

          #hlp     -o <ARG> Specify outputfile.
          #hlp
            o) 
               case $execmode in
                 default) execmode="logging"; outputfile="$OPTARG" ;;
                 logging) fatal "I cowardly refuse to produce more than one log." ;;
                  remote) outputfile="$OPTARG" ;;
                   nolog) fatal "Options '-q' and '-o' are mutually exclusive." ;;
                       *) warning "Unspecified modus operandi. Ignore '-o'." ;;
               esac
               ;;

          #hlp     -q       Supress creating a logfile.
          #hlp
            q) 
               case $execmode in
                 default) execmode="nolog"; unset outputfile ;;
                 logging) fatal "Options '-q' and '-o' are mutually exclusive." ;;
                  remote) fatal "Options '-q' and '-R' are mutually exclusive." ;;
                   nolog) warning "Can it really be quieter than quiet? Ignore '-q'." ;;
                       *) warning "Unspecified modus operandi. Ignore '-q'." ;;
               esac
               ;;

          #hlp     -f       Force to use supplied values (or defaults).
          #hlp              This will overwrite any environment variable.
          #hlp              Use with great care.
          #hlp
            f) forceScriptValues="true" ;;

          #hlp     -k       Keep temporarily created 'settings.ini'.
          #hlp
            k) settingsini_nocleanup="true" ;;

          #hlp     -Q <ARG> Which type of job script should be produced.
          #hlp              Arguments currently implemented: pbs-gen, bsub-rwth, slurm-rwth
          #hlp              Mandatory for remote execution, can be set in rc.
          #hlp
            Q) request_qsys="$OPTARG" ;;

          #hlp     -P <ARG> Account to project (BSUB) or account (SLURM).
          #hlp              
            P) 
               bsub_project="$OPTARG"
               request_qsys="bsub-rwth"  
               case $execmode in
                 default) execmode="remote" ;;
                 logging) execmode="remote" ;;
                  remote) : ;;
                   nolog) fatal "Options '-q' and '-P' are mutually exclusive." ;;
                       *) warning "Unspecified modus operandi. Ignore '-P'." ;;
               esac
               ;;

          #hlp     -s       Suppress logging messages of the script.
          #hlp              (May be specified multiple times.)
          #hlp
            s) (( stay_quiet++ )) ;;

          #hlp     -h       this help.
          #hlp
            h) helpme ;;

          #hlp     -H       Display the manual. 
          #hlp              Requires a pdfviewer and the manual to be installed.
            H) display_manual ;;

           \?) fatal "Invalid option: -$OPTARG." ;;

            :) fatal "Option -$OPTARG requires an argument." ;;

        esac
    done

    # Shift all variables processed to far
    shift $((OPTIND-1))

    if [[ -z "$1" ]] ; then return ; fi

    # If an inputfile has not yet been specified,
    # the argument after the options will be taken as the input file,
    # thus enabeling "multiwfn [<file>]" as a default operation.
    if [[ -z $inputfile ]] ; then
      # If a filename is specified, it must exist, otherwise exit
      is_readable_file_or_exit "$1" && inputfile="$1" 
      shift
    fi
    # If a file has already been specified issue a warning 
    # that the addidtional flag has no effect.
    warn_additional_args "$@"
}

run_interactive ()
{
    export KMP_STACKSIZE=$requested_KMP_STACKSIZE
    message "Memory (KMP_STACKSIZE) is set to $KMP_STACKSIZE."
    Multiwfnpath="$use_Multiwfnpath"
    message "Using following version: $Multiwfnpath"
    export PATH="$PATH:$Multiwfnpath"
    export Multiwfnpath

    # Print some informations of the platform
		message "This is $(uname -n)"
		message "OS $(uname -o) ($(uname -p))"
		message "Running on $requested_numCPU $(grep 'model name' /proc/cpuinfo|uniq|cut -d ':' -f 2)."

    ulimit -s unlimited

    # Now everything should be set an we can call the program.
    # Decide how to call the program analogous to setting permissions
    #    input    4
    #    command  2
    #    output   1
    # Therefore there are 8 callmodes.
    # Two will fail, i.e. 2 (only com) and 3 (com + out).
    #
    # Initialise variable; i.e. just call the program

    local callmode=0
    [[ -n $inputfile ]]   && ((callmode+=4))
    [[ -n $commandfile ]] && ((callmode+=2))
    [[ -n $outputfile ]]  && ((callmode+=1))

    case $callmode in

        7) Multiwfn "$inputfile" < "$commandfile" > "$outputfile" ;;
        6) Multiwfn "$inputfile" < "$commandfile" ;;
        5) script -c "Multiwfn \"$inputfile\"" "$outputfile" ;;
        4) Multiwfn "$inputfile" ;;
        1) script -c "Multiwfn" "$outputfile" ;;
        0) Multiwfn  ;;
        *) fatal "This set-up would cause Multiwfn to crash." ;;

    esac

    remove_temp_settingsini
}

runRemote ()
{
    message "Remote mode selected, creating a job script instead."
    local queue="$1" queue_short submitscript
    [[ -z $queue ]] && fatal "No queueing systen selected. Abort."
    queue_short="${queue%-*}"
    submitscript="${outputfile%.*}.${queue_short}.bash"
    debug "Selected queue: $queue; short: $queue_short"
    debug "Will write submitscript to: $submitscript"

    if [[ -e $submitscript ]] ; then
      fatal "Designated submitscript '$submitscript' already exists."
    fi
    [[ -z $inputfile ]]   && fatal "No inputfile specified. Abort."
    [[ -z $commandfile ]] && fatal "No commands specified. Abort."
    [[ -z $outputfile ]]  && fatal "No outputfile selected. Abort."

    # Open file descriptor 9 for writing
    exec 9> "$submitscript"

    echo "#!/bin/bash" >&9
    echo "# Submission script automatically created with $scriptname" >&9

    local overhead_KMP_STACKSIZE
    overhead_KMP_STACKSIZE=$(( requested_KMP_STACKSIZE + 5000000 ))

    # Header is different for the queueing systems
    if [[ "$queue" =~ [Pp][Bb][Ss] ]] ; then
      cat >&9 <<-EOF
			#PBS -l nodes=1:ppn=$requested_numCPU
			#PBS -l mem=$overhead_KMP_STACKSIZE
			#PBS -l walltime=$requested_walltime
			#PBS -N ${submitscript%.*}
			#PBS -m ae
			#PBS -o $submitscript.o\${PBS_JOBID%%.*}
			#PBS -e $submitscript.e\${PBS_JOBID%%.*}
			EOF
    elif [[ "$queue" =~ [Bb][Ss][Uu][Bb]-[Rr][Ww][Tt][Hh] ]] ; then
      cat >&9 <<-EOF
			#BSUB -n $requested_numCPU
			#BSUB -a openmp
			#BSUB -M $(( overhead_KMP_STACKSIZE / 1000000 ))
			#BSUB -W ${requested_walltime%:*}
			#BSUB -J ${submitscript%.*}
			#BSUB -N 
			#BSUB -o $submitscript.o%J
			#BSUB -e $submitscript.e%J
			EOF
      if [[ "$PWD" =~ [Hh][Pp][Cc] ]] ; then
        echo "#BSUB -R select[hpcwork]" >&9
      fi
      if [[ -n $bsub_project ]] ; then
        echo "#BSUB -P $bsub_project" >&9
      fi
    elif [[ "$queue" =~ [Ss][Ll][Uu][Rr][Mm] ]] ; then
      cat >&9 <<-EOF
			#SBATCH --nodes=1
			#SBATCH --ntasks=1
			#SBATCH --cpus-per-task=$requested_numCPU
			#SBATCH --mem-per-cpu=$(( overhead_KMP_STACKSIZE / 1000000 / requested_numCPU ))
			#SBATCH --time=$requested_walltime
			#SBATCH --job-name=${submitscript%.*}
			#SBATCH --mail-type=END,FAIL
			#SBATCH --output="${submitscript}.o%j"
			#SBATCH --error="${submitscript}.e%j"
			EOF
      if [[ "$queue" =~ [Rr][Ww][Tt][Hh] ]] ; then
        if [[ "$PWD" =~ [Hh][Pp][Cc] ]] ; then
          echo "#SBATCH --constraint=hpcwork" >&9
        fi
        if [[ -n $bsub_project ]] ; then
          echo "#SBATCH --account=$bsub_project" >&9
        fi
      fi
      queue_wrapper='srun'
    else
      fatal "Unrecognised queueing system '$queue'."
    fi

    # The body is the same for all queues (so far)
    cat >&9 <<-EOF
		
		echo "This is \$(uname -n)"
		echo "OS \$(uname -o) (\$(uname -p))"
		echo "Running on $requested_numCPU \$(grep 'model name' /proc/cpuinfo|uniq|cut -d ':' -f 2)."
		echo "Calculation $inputfile and $commandfile from $PWD."
		echo "Working directry is $PWD"
		
		cd "$PWD"
		
		export PATH="\$PATH:$use_Multiwfnpath"
		export Multiwfnpath="$use_Multiwfnpath"
		export KMP_STACKSIZE=$requested_KMP_STACKSIZE
		
		multiwfn_cmd=\$( command -v Multiwfn ) || { echo "Command not found: Multiwfn." >&2 ; exit 1 ; }
		ulimit -s unlimited
		
		echo "Start: \$(date)"
		EOF
    if [[ -z $queue_wrapper ]] ; then
      echo "\"\$multiwfn_cmd\" \"$inputfile\" < \"$commandfile\" > \"$outputfile\"" >&9
    else
      echo "$queue_wrapper \"\$multiwfn_cmd\" \"$inputfile\" < \"$commandfile\" > \"$outputfile\"" >&9
    fi
    #shellcheck disable=SC2016
    echo 'echo "End:   $(date)"' >&9
		
    # Cleanup
    if [[ $settingsini_nocleanup =~ [Tt][Rr][Uu][Ee]? ]] ; then
      cat >&9 <<-EOF
			echo "Switch prevents cleaning up 'settings.ini'."
			EOF
    else
      cat >&9 <<-EOF
			[[ -e $PWD/settings.ini ]] && rm -v $PWD/settings.ini
			EOF
    fi

    # Close file descriptor
    exec 9>&-

    message "Created submit script, use"
    if [[ "$queue" =~ [Pp][Bb][Ss] ]] ; then
      message "  qsub $submitscript"
    elif [[ "$queue" =~ [Bb][Ss][Uu][Bb]-[Rr][Ww][Tt][Hh] ]] ; then
      message "  bsub < $submitscript"
    elif [[ "$queue" =~ [Ss][Ll][Uu][Rr][Mm] ]] ; then
      message "  sbatch $submitscript"
    fi
    message "to start the job."

    return 0
}

#
# Begin main script
#

# Sent logging information to stdout
exec 3>&1

# Secret debugging switch
if [[ "$1" == "debug" ]] ; then
  exec 4>&1
  stay_quiet=0 
  shift 
else
  exec 4> /dev/null
fi

#
# Setting some defaults
#

# Print all information by default
stay_quiet=0

# Specify default Walltime, this is only relevant for remote
# execution as a header line for PBS.
requested_walltime="24:00:00"

# Specify a default value for the memory
requested_KMP_STACKSIZE=64000000 

# This corresponds to  nthreads=<digit(s)> in the settings.ini
requested_numCPU=4

# Use the graphical interface by default
request_gui_version="yes"

# Necessary to resolve a clash between -q and -o
execmode="default"

# Select a queueing system (pbs-gen/bsub-rwth/slurm-rwth)
request_qsys="pbs-gen"

# Account to project (only for rwth)
bsub_project=default

# By default clean up the temporary setting.ini
settingsini_nocleanup="false"

# By default the variables set through the environment should be taken
forceScriptValues="false"


# Ensure that in/outputfile variables are empty
unset inputfile
unset commandfile
unset outputfile

# Who are we and where are we?
scriptname="$(get_absolute_filename "${BASH_SOURCE[0]}" "installname")"
debug "Script is called '$scriptname'"
# remove scripting ending (if present)
scriptbasename=${scriptname%.sh} 
debug "Base name of the script is '$scriptbasename'"
scriptpath="$(get_absolute_dirname  "${BASH_SOURCE[0]}" "installdirectory")"
debug "Script is located in '$scriptpath'"

if [[ "$1" =~ ^[Ll][Ii][Cc][Ee][Nn][Ss][Ee]$ ]] ; then
  [[ -r "$scriptpath/LICENSE.txt" ]] || fatal "No license file found. Your copy of the repository might be corrupted."
  if command -v less &> /dev/null ; then
    less "$scriptpath/LICENSE.txt"
  else
    cat "$scriptpath/LICENSE.txt"
  fi
  message "Displayed license and will exit."
  exit 0
fi

# Set the verion of the script
[[ -r "$scriptpath/VERSION" ]] && . "$scriptpath/VERSION"
version=${version:-undefined}
versiondate=${versiondate:-undefined}

# Check for settings in three default locations (increasing priority):
#   install path of the script, user's home directory, current directory
runMultiwfn_rc_loc="$(get_rc "$scriptpath" "/home/$USER" "$PWD")"
debug "runMultiwfn_rc_loc=$runMultiwfn_rc_loc"

# Load custom settings from the rc

if [[ -n $runMultiwfn_rc_loc ]] ; then
  #shellcheck source=./runMultiwfn.rc
  . "$runMultiwfn_rc_loc"
  message "Configuration file '$runMultiwfn_rc_loc' applied."
else
  debug "No custom settings found."
fi

# Evaluate Options

process_options "$@"
set_outputfile "$outputfile"
requested_KMP_STACKSIZE=$(check_environment_memory "$requested_KMP_STACKSIZE")
if [[ $request_gui_version =~ [Yy][Ee][Ss] ]] ; then
  use_Multiwfnpath=$(get_Multiwfnpath_or_exit "$installpath_Multiwfn_gui") || exit 1
  debug "Using Multiwfnpath: $use_Multiwfnpath"
elif [[ $request_gui_version =~ [Nn][Oo] ]] ; then
  use_Multiwfnpath=$(get_Multiwfnpath_or_exit "$installpath_Multiwfn_nogui") || exit 1
  debug "Using Multiwfnpath: $use_Multiwfnpath"
else
  fatal "Cannot determine which modus (gui/nogui) to use."
fi

write_temp_settingsini

if [[ "$execmode" == "remote" ]] ; then
  debug "Running remote."
  runRemote "$request_qsys"
else
  debug "Running interactive."
  run_interactive
fi

#hlp   AUTHOR    : Martin
message "Thank you for travelling with $scriptname ($version, $versiondate)."
exit 0

