#! /bin/bash

#Multiwfn initialization script
# See CHANGES.txt
version="0.5.0"
versiondate="2018-04-xx"

# The following two lines give the location of the installation.
# They can be set in the rc file, too.
installpath_Multiwfn_gui="/path/is/not/set"
installpath_Multiwfn_nogui="/path/is/not/set"

# See the readme file for more details. 

#####
#
# The actual script begins here. 
# You might not want to make modifications here.
# If you do improve it, I would be happy to learn about it.
#

#
# Get some informations of the platform
#
# Move this to install routine and hardcode in rc (?)
nodename=$(uname -n)
operatingsystem=$(uname -o)
architecture=$(uname -p)
processortype=$(grep 'model name' /proc/cpuinfo|uniq|cut -d ':' -f 2)


#
# Display help
#
helpme ()
{
cat <<-EOF
   This is $scriptname!

   This script is a wrapper intended for MultiWFN $installpath_Multiwfn_gui (linux).
   A detailed description on how to install MultiWFN and/or
   manipulate this script is located in readme.txt distributed 
   alongside this script.
   This software comes with absolutely no warrenty. None. Nada.

   VERSION    :   $version
   DATE       :   $versiondate

   USAGE      :   $scriptname [options] [IPUT_FILE]

   VARIABLES  :

     The script will attempt to read variables necessary for
     the execution of MultiWFN from the environment settings.
     If they are unset, they will be replaced by default values
     or they can be specified via option switches.

   OPTIONS    :
    
     -m <ARG> Define memory to be used per thread in byte.
                (KMP_STACKSIZE; Default: 64000000)
                [Option has no effect if set though environment.]

     -p <ARG> Define number of threads to be used.
                (Default: 2)
                [Option has no effect if set though environment.]

     -l <ARG> Legacy mode (deprecated): Request different version.      
              With version 0.5.0 of the script, this has been removed 
              and no longer has any effect.

     -g       run without GUI

     -R       Execute in remote mode.
              This option creates a job submission script for PBS
              instead of running MultiWFN.

     -w <ARG> Define maximum walltime.
                Format: [[HH:]MM:]SS
                (Default: $requested_walltime)

     -q       Supress creating a logfile.

     -o <ARG> Specify outputfile.

     -i <ARG> Specify file on which MultiWFN should operate.
  
     -c <ARG> Specify a file, that contains a sequence of 
              numbers, that can be interpreted by MultiWFN.

     -f       Force to use supplied values (or defaults).
              This will overwrite any environment variable.
              Use with great care.

     -h       this help.

   AUTHOR    : Martin
               Complaints via chemistry.stackexchange.com

EOF
exit 0    
}

## The following will replace above function, once everything is distributed
## #
## # Print some helping commands
## # The lines are distributed throughout the script and grepped for
## #
## 
## helpme ()
## {
##     local line
##     local pattern="^[[:space:]]*#hlp[[:space:]]?(.*)?$"
##     while read -r line; do
##       [[ "$line" =~ $pattern ]] && eval "echo \"${BASH_REMATCH[1]}\""
##     done < <(grep "#hlp" "$0")
##     exit 0
## }

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
        [ ! -z "$2" ] && fatal "Value for $2 ($1) is no integer."
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
  while [[ ! -z $1 ]] ; do
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
    while [[ ! -z $1 ]]; do
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
    echo "${return_outfile_name%.*}.out"
    debug "${return_outfile_name%.*}.out"
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
  
    if [[ ! -z $KMP_STACKSIZE ]] ; then
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
    if [[ ! -z $Multiwfnpath ]] ; then
      warning "Multiwfnpath is set to '$Multiwfnpath'; this will be overwritten."
      unset Multiwfnpath
      debug "Unsetting Multiwfnpath."
    fi
}

check_Multiwfn_install ()
{
    local test_path="$1"
    debug "check_Multiwfn_install: test_path=$test_path"
    debug "$(ls $test_path)"
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
      settingsini_source_loc="$PWD/settings.ini"
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
    [[ settingsini_nocleanup =~ [Tt][Rr][Uu][Ee]? ]] && return 0
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
    local OPTIND=1 

    while getopts :hqm:p:l:gRw:o:i:c:fk options ; do
        case $options in

            h) helpme ;;

            q) 
               case $execmode in
                 default) execmode="nolog"; unset outputfile ;;
                 logging) fatal "Options '-q' and '-o' are mutually exclusive." ;;
                  remote) fatal "Options '-q' and '-R' are mutually exclusive." ;;
                   nolog) warning "Can it really be quieter than quiet? Ignore '-q'." ;;
                       *) warning "Unspecified modus operandi. Ignore '-q'." ;;
               esac
               ;;

            m) 
               if [[ -z $requested_KMP_STACKSIZE ]] ; then 
                 validate_integer "$OPTARG" "the memory"
                 if (( OPTARG == 0 )) ; then
                   fatal "KMP_STACKSIZE must not be zero."
                 fi
                 requested_KMP_STACKSIZE="$OPTARG" 
               else
                 fatal "Option '-m' has been specified multiple times."
               fi ;;

            p) 
               validate_integer "$OPTARG" "the number of threads"
               if (( OPTARG == 0 )) ; then
                 fatal "Number of threads must not be zero."
               fi
               requested_numCPU="$OPTARG" 
               ;;
            l)
               fatal "Legacy mode has been removed in script version 0.5.0"
               ;;

            g) 
               request_gui_version="no"
               message "Running without GUI."
               if [[ -z $installpath_Multiwfn_nogui ]] ; then
                 fatal "There is no version set for running without GUI."
               fi
               ;;

            R)
               case $execmode in
                 default) execmode="remote" ;;
                 logging) execmode="remote" ;;
                  remote) warning "Already operating in remote mode. Ignore '-R'." ;;
                   nolog) fatal "Options '-q' and '-R' are mutually exclusive." ;;
                       *) warning "Unspecified modus operandi. Ignore '-R'." ;;
               esac
               ;;

            w) requested_walltime=$(format_duration_or_exit "$OPTARG")
               ;;

            o) 
               case $execmode in
                 default) execmode="logging"; outputfile="$OPTARG" ;;
                 logging) fatal "I cowardly refuse to produce more than one log." ;;
                  remote) outputfile="$OPTARG" ;;
                   nolog) fatal "Options '-q' and '-o' are mutually exclusive." ;;
                       *) warning "Unspecified modus operandi. Ignore '-o'." ;;
               esac
               ;;

            i) 
               if [[ -z $inputfile ]] ; then
                 inputfile="$OPTARG" 
                 # If a filename is specified, it must exist, otherwise exit
                 is_readable_file_or_exit "$inputfile"
               else
                 fatal "I only know how to operate on one inputfile."
               fi 
               ;;

            c) 
               if [[ -z $commandfile ]] ; then
                 commandfile="$OPTARG" 
                 # If a filename is specified, it must exist, otherwise exit
                 is_readable_file_or_exit "$commandfile"
               else 
                 fatal "I can only handle one set of commands."
               fi
               ;;

            f) forceScriptValues="true" ;;

            k) settingsini_nocleanup="true" ;;

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
    [[ ! -z $inputfile ]]   && ((callmode+=4))
    [[ ! -z $commandfile ]] && ((callmode+=2))
    [[ ! -z $outputfile ]]  && ((callmode+=1))

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
    message "Remote mode selected, creating PBS job script instead."
    if [[ ! -e ${outputfile%.*}.sh ]] ; then
      submitscript="${outputfile%.*}.sh"
    else
      fatal "Designated submitscript ${outputfile%.*}.sh already exists."
    fi
    [[ -z $inputfile ]]   && fatal "No inputfile specified. Abort."
    [[ -z $commandfile ]] && fatal "No commands specified. Abort."
    [[ -z $outputfile ]]  && fatal "No outputfile selected. Abort."

    cat > "$submitscript" <<-EOF
#!/bin/sh
#PBS -l nodes=1:ppn=$requested_numCPU
#PBS -l mem=$requested_KMP_STACKSIZE
#PBS -l walltime=$requested_walltime
#PBS -N ${submitscript%.*}
#PBS -m ae
#PBS -o $submitscript.o\${PBS_JOBID%%.*}
#PBS -e $submitscript.e\${PBS_JOBID%%.*}

echo "This is $nodename"
echo "OS $operatingsystem ($architecture)"
echo "Running on $requested_numCPU $processortype."
echo "Calculation $inputfile and $commandfile from $PWD."
echo "Working directry is \$PBS_O_WORKDIR"
cd \$PBS_O_WORKDIR

export PATH="\$PATH:$use_Multiwfnpath"
export Multiwfnpath="$use_Multiwfnpath"
export KMP_STACKSIZE=$requested_KMP_STACKSIZE

date
Multiwfn "$inputfile" < "$commandfile" > "$outputfile"
date

EOF

message "Created submit PBS script, to start the job:"
message "  qsub $submitscript"
message "The temporarily created 'settings.ini' cill not be cleaned up."

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

# Check for settings in three default locations (increasing priority):
#   install path of the script, user's home directory, current directory
runMultiwfn_rc_loc="$(get_rc "$scriptpath" "/home/$USER" "$PWD")"
debug "runMultiwfn_rc_loc=$runMultiwfn_rc_loc"

# Load custom settings from the rc

if [[ ! -z $runMultiwfn_rc_loc ]] ; then
  #shellcheck source=/home/te768755/devel/runMultiwfn.bash/runMultiwfn.rc
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

[[ "$execmode" == "remote" ]] && runRemote

run_interactive

message "Thank you for travelling with $scriptname."
exit 0

