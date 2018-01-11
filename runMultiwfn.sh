#! /bin/bash

#Multiwfn initialization script
scriptname=${0##*\/} # Remove trailing path
scriptname=${scriptname%.sh} # remove scripting ending (if present)

# See CHANGES.txt

version="0.4.4"
versiondate="2018-01-11"

#
# In order to make the installation and setup easier,
# define a variable that contains the rootpath 
# for the MultiWFN installation 
# The following path must be modified to fit your system
installPathMultiWFN="/home/chemsoft/multiwfn"

# Which is the installed version of MultiWFN?
# This should be a directory inside the above path.
# In this directory the executable (and the library file
# if using a legacy version) should be located.
# This must also be modified for your system
installPrefixMultiWFN="Multiwfn_"

# At the time of writing the most up-to-date version was 3.4.1
installVersionMultiWFN="3.4.1"

# In the multiwfn-root directory should be multiple directories
# they should be named with the specified prefix, version number
# and a suffix indicating the number of professors it uses
# like _cpu<digit(s)>
installSuffixMultiWFN="_cpu"

# This corresponds to  nthreads=<digit(s)> in the settings.ini
# <digit(s)> will be determined by the requested number
requested_NumCPU=2
# If no directory with this set-up exists, it will count down
# the variable, until it finds a suitable option or reaches 0.

# For example, in the above case the following is a valid 
# path and excecuteable:
#   "/home/chemsoft/multiwfn/Multiwfn_3.4.1_cpu2/Multiwfn" 

# If available, the program can be run without a GUI, that is
# a different executeable. The script assumes that to the version
# the letters 'ng' are appended, hence the following
#   "/home/chemsoft/multiwfn/Multiwfn_3.4.1ng_cpu2/Multiwfn" 
# is a valit path to the executeable.
# This mode must be enabled here.
installNoguiMultiWFN="no"
#  installNoguiMultiWFN="yes"

# Specify default Walltime, this is only relevant for remote
# execution as a header line for PBS.
requested_Walltime="24:00:00"

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
nodename=$(uname -n)
operatingsystem=$(uname -o)
architecture=$(uname -p)
processortype=$(grep 'model name' /proc/cpuinfo|uniq|cut -d ':' -f 2)

#
# Set some default values for other variables
#

# Necessary to resolve a clash between -q and -o
execmode="default"
# By default the variables set through the environment should be taken
forceScriptValues="false"
# Do not use legacy version
legacyBinary="false"
# Ensure that inputfile variables are empty
unset inputfile
unset commandfile

#
# Display help
#
helpme ()
{
cat <<-EOF
   This is $scriptname!

   This script is a wrapper intended for MultiWFN $installVersionMultiWFN (linux).
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

     -l <ARG> Legacy mode: Request different version.      
              Currently in use $installVersionMultiWFN
              Previously in use 3.4.1, 3.3.8
              Use with great care.
              [Option has no effect if set though environment.]

     -g       run without GUI

     -R       Execute in remote mode.
              This option creates a job submission script for PBS
              instead of running MultiWFN.

     -w <ARG> Define maximum walltime.
                Format: [[HH:]MM:]SS
                (Default: $requested_Walltime)

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

#
# Print logging information and warnings nicely.
# If there is an unrecoverable error: display a message and exit.
#

message ()
{
    echo "INFO   : " "$*"
}

indent ()
{
    echo -n "INFO   : " 
}

warning ()
{
    echo "WARNING: " "$*" >&2
}

fatal ()
{
    echo "ERROR  : " "$*" >&2
    exit 1
}

#
# Test if a given value is an integer
#

isInteger()
{
    [[ $1 =~ ^[[:digit:]]+$ ]]
}

validateInteger () 
{
    if ! isInteger "$1"; then
        [ ! -z "$2" ] && fatal "Value for $2 ($1) is no integer."
          [ -z "$2" ] && fatal "Value \"$1\" is no integer."
    fi
}

validateDuration ()
{
    local checkDuration=$1
    # Split time in HH:MM:SS
    # Strips away anything up to and including the rightmost colon
    # strips nothing if no colon present
    # and tests if the value is numeric
    # this is assigned to seconds
    local truncDuration_Seconds=${checkDuration##*:}
    validateInteger "$truncDuration_Seconds" "seconds"
    # If successful value is stored for later assembly
    #
    # Check if the value is given in seconds
    # "${checkDuration%:*}" strips shortest match ":*" from back
    # If no colon is present, the strings are identical
    if [[ ! "$checkDuration" == "${checkDuration%:*}" ]]; then
        # Strip seconds and colon
        checkDuration="${checkDuration%:*}"
        # Strips away anything up to and including the rightmost colon
        # this is assigned as minutes
        # and tests if the value is numeric
        local truncDuration_Minutes=${checkDuration##*:}
        validateInteger "$truncDuration_Minutes" "minutes"
        # If successful value is stored for later assembly
        #
        # Check if value was given as MM:SS same procedure as above
        if [[ ! "$checkDuration" == "${checkDuration%:*}" ]]; then
            #Strip minutes and colon
            checkDuration="${checkDuration%:*}"
            # # Strips away anything up to and including the rightmost colon
            # this is assigned as hours
            # and tests if the value is numeric
            local truncDuration_Hours=${checkDuration##*:}
            validateInteger "$truncDuration_Hours" "hours"
            # Check if value was given as HH:MM:SS if not, then exit
            if [[ ! "$checkDuration" == "${checkDuration%:*}" ]]; then
                fatal "Unrecognised duration format."
            fi
        fi
    fi

    # Modify the duration to have the format HH:MM:SS
    # disregarding the format of the user input
    # keep only 0-59 seconds stored, let rest overflow to minutes
    local finalDuration_Seconds=$((truncDuration_Seconds % 60))
    # Add any multiple of 60 seconds to the minutes given as input
    truncDuration_Minutes=$((truncDuration_Minutes + truncDuration_Seconds / 60))
    # save as minutes what cannot overflow as hours
    local finalDuration_Minutes=$((truncDuration_Minutes % 60))
    # add any multiple of 60 minutes to the hours given as input
    local finalDuration_Hours=$((truncDuration_Hours + truncDuration_Minutes / 60))

    # Format string and save on variable
    printf -v requested_Walltime "%d:%02d:%02d" $finalDuration_Hours $finalDuration_Minutes \
                                             $finalDuration_Seconds
}

#
# Test, whether we can access the given file/directory
#

isFile ()
{
    [[ -f $1 ]]
}

isReadable ()
{
    [[ -r $1 ]]
}

isReadableFileOrExit ()
{
    isFile "$1"     || fatal "Specified file '$1' is no file or does not exist."
    isReadable "$1" || fatal "Specified file '$1' is not readable."
}

# 
# Issue warning if options are ignored.
#

checkTooManyArgs ()
{
    while [[ ! -z $1 ]]; do
      warning "Specified option $1 will be ignored."
      shift
    done
}

#
# Determine or validate outputfiles
#

setDefaultOutput ()
{
  # In default mode logging is enabled but no filename is specified.
  # If an output already exists from a previous run it must not be overwritten.
  # Default name for the output is generated from the name of the script and input
  local savsuffix=1
  if [[ -z $outputfile ]] ; then
    if [[ ! -z $inputfile ]] ; then
      outputfile="${inputfile%.*}."
    fi
    outputfile="$outputfile$scriptname.out"
    if ! isFile "$outputfile" ; then
      return
    fi
    while isFile "$outputfile.$savsuffix" ; do
      (( savsuffix++ ))
    done
    message "Prevent overwriting of existing file(s)."
    indent
    mv -v "$outputfile" "$outputfile.$savsuffix"
  fi
}

#
# Check if logging was activated or deactivated
#

setLoggingOptions ()
{
    case "$execmode" in

      default) setDefaultOutput ;;
      logging) 
               # If an outputfile is specified, assume that the user 
               # wants to overwrite existing ones. Issue warning nevertheless.
               if isFile "$outputfile" ; then
                 warning "Output '$outputfile' from a previous run will be overwritten."
               fi
               ;;
       remote) setDefaultOutput ;;
        nolog) message "Logging is disabled." ;;
        *    ) fatal "(Unknown error in setLoggingOptions)" ;;

    esac
}

#
# Assign the values from or to environment variables
#

checkAndSetMemory ()
{
    if [[ -z $KMP_STACKSIZE ]] ; then
      # Checks if value has been set through the environment
      if [[ -z $requested_KMP_STACKSIZE ]] ; then 
        # Checks if it has been set via the options
        requested_KMP_STACKSIZE=64000000 
      fi
      # Use and export those values
      message "Setting KMP_STACKSIZE to $requested_KMP_STACKSIZE."
      export KMP_STACKSIZE=$requested_KMP_STACKSIZE
    elif [[ ! -z $KMP_STACKSIZE && "$forceScriptValues" = "true" ]] ; then
      # Issue warning is environment settings will be overwritten
      warning "Overwriting environment variable for memory"
      warning "from $KMP_STACKSIZE to $requested_KMP_STACKSIZE."
      # Use forced values
      export KMP_STACKSIZE=$requested_KMP_STACKSIZE
    else
      # Issue information warning
      message "KMP_STACKSIZE is set to $KMP_STACKSIZE."
    fi
}

checkIfInPath ()
{
    # Check if there could be clashes if an executeable has been set 
    # via the environment
    local pattern="(^|:)([^:]*/[Mm]ulti[Ww][Ff][Nn]/[^:]*)(:|$)"
    local storepath removefrompath
    if [[ "$PATH" =~ $pattern ]]; then
      # Only for debugging: message "Have it here: ${BASH_REMATCH[2]}"
      storepath="${BASH_REMATCH[2]}"
      # Reminder ${BASH_REMATCH[0]} is the full match
      # Store that value, if it needs to be removed
      if [[ ${BASH_REMATCH[1]} == "${BASH_REMATCH[3]}" ]] ; then
        removefrompath="${BASH_REMATCH[2]}:"
      else
        removefrompath="${BASH_REMATCH[0]}"
      fi
    else
      return 1
    fi

    if [[ "$legacyBinary" == "true" ]] ; then
      local storelibpath removefromlibpath
      if [[ "$LD_LIBRARY_PATH" =~ $pattern ]]; then
        # Only for debugging message "Have it here: ${BASH_REMATCH[2]}"
        storelibpath="${BASH_REMATCH[2]}"
        if [[ ${BASH_REMATCH[1]} == "${BASH_REMATCH[3]}" ]] ; then
          removefromlibpath="${BASH_REMATCH[2]}:"
        else
          removefromlibpath="${BASH_REMATCH[0]}"
        fi
      fi
      if [[ ! "$storepath" == "$storelibpath" ]] ; then
        # Avoid using a library from a different binary
        fatal "Library path does not match executable path. Something is seriously wrong."
      fi
    fi
    # If it is in PATH, but we want to force defaults, we need to remove it
    # and re-add it
    if [[ "$forceScriptValues" == "true" ]] ; then
      PATH="${PATH/$removefrompath/}"
      [[ "$legacyBinary" == "true" ]] && LD_LIBRARY_PATH="${LD_LIBRARY_PATH/$removefromlibpath/}"
      warning "Path to executable has already been set."
      warning "Overwriting existing choice."
      return 1
    fi
    
    # If we found it in PATH, then we use it
    Multiwfnpath="$storepath"
}

checkIfPathExists ()
{
    local Multiwfnsubpath="$installPrefixMultiWFN$installVersionMultiWFN$installSuffixMultiWFN"
    local test_CPUs=$requested_NumCPU
    while [[ ! -d "$installPathMultiWFN/$Multiwfnsubpath$test_CPUs" ]] ; do
      warning "Cannot find '$Multiwfnsubpath$test_CPUs', try next."
      (( test_CPUs-- ))
      (( test_CPUs == 0 )) && fatal "Cannot find suitable excecutable."
    done
    Multiwfnpath="$installPathMultiWFN/$Multiwfnsubpath$test_CPUs"
}

checkAndSetMultiWFN ()
{
    # If it is already included in PATH, assume everything is ok and continue 
    checkIfInPath && return 0
    checkIfPathExists

    export PATH="$PATH:$Multiwfnpath"
    export Multiwfnpath
    # Only any longer necessary for the legacy option
    [[ "$legacyBinary" == "true" ]] && export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$Multiwfnpath"
    message "Using following version:"
    message "  $Multiwfnpath"
}

# Check if a local settings.ini exists and warn
checkLocalSettinsIni ()
{
    [[ -e ./settings.ini ]] && warning "Found local 'settings.ini'. This will overwrite any option set through the script."
}

#
# Process Options
#

settings ()
{
    local OPTIND=1 

    while getopts :hqm:p:l:gRw:o:i:c:f options ; do
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
                 validateInteger "$OPTARG" "the memory"
                 if (( OPTARG == 0 )) ; then
                   fatal "KMP_STACKSIZE must not be zero."
                 fi
                 requested_KMP_STACKSIZE="$OPTARG" 
               else
                 fatal "Option '-m' has been specified multiple times."
               fi ;;

            p) 
               validateInteger "$OPTARG" "the number of threads"
               if (( OPTARG == 0 )) ; then
                 fatal "Number of threads must not be zero."
               fi
               requested_NumCPU="$OPTARG" 
               ;;
            l)
               warning "Legacy mode chosen."
               installVersionMultiWFN="$OPTARG"
               legacyBinary="true"  
               ;;

            g) 
               if [[ $installNoguiMultiWFN == "yes" ]] ; then
                 message "No GUI will be available."
                 installVersionMultiWFN="${installVersionMultiWFN}ng" 
               else
                 fatal "Running without GUI is disabled."
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

            w) validateDuration "$OPTARG"  ;;

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
                 isReadableFileOrExit "$inputfile"
                 # isFile "$inputfile" || fatal "Inputfile '$inputfile' is no file or does not exist."
                 # isReadable "$inputfile" || fatal "Inputfile '$inputfile' is not readable."
               else
                 fatal "I only know how to operate on one inputfile."
               fi 
               ;;

            c) 
               if [[ -z $commandfile ]] ; then
                 commandfile="$OPTARG" 
                 # If a filename is specified, it must exist, otherwise exit
                 isReadableFileOrExit "$commandfile"
                 # isFile "$commandfile" || fatal "Inputfile '$commandfile' is no file or does not exist."
                 # isReadable "$commandfile" || fatal "Inputfile '$commandfile' is not readable."
               else 
                 fatal "I can only handle one set of commands."
               fi
               ;;

            f) forceScriptValues="true" ;;

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
      isReadableFileOrExit "$1" && inputfile="$1" 
      shift
    fi
    # If a file has already been specified issue a warning 
    # that the addidtional flag has no effect.
    checkTooManyArgs "$@"
}

runInteractive ()
{
    # Now everything should be set an we can call the program.
    # Decide how to call the program analogous to setting permissions
    #    input    4
    #    command  2
    #    output   1
    # Therefore there are 8 callmodes.
    # Two will fail, i.e. 2 (only com) and 3 (com + out).
    #
    # Initialise variable; i.e. just call the program

    callmode=0
    [[ ! -z $inputfile ]]   && ((callmode+=4))
    [[ ! -z $commandfile ]] && ((callmode+=2))
    [[ ! -z $outputfile ]]  && ((callmode+=1))

    case $callmode in

        0) Multiwfn  ;;
        1) script -c "Multiwfn" "$outputfile" ;;
        4) Multiwfn "$inputfile" ;;
        5) script -c "Multiwfn \"$inputfile\"" "$outputfile" ;;
        6) Multiwfn "$inputfile" < "$commandfile" ;;
        7) Multiwfn "$inputfile" < "$commandfile" > "$outputfile" ;;
        *) fatal "This set-up would cause Multiwfn to crash." ;;

    esac
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
#PBS -l nodes=1:ppn=$requested_NumCPU
#PBS -l mem=$requested_KMP_STACKSIZE
#PBS -l walltime=$requested_Walltime
#PBS -N ${submitscript%.*}
#PBS -m ae
#PBS -o $submitscript.o\${PBS_JOBID%%.*}
#PBS -e $submitscript.e\${PBS_JOBID%%.*}

echo "This is $nodename"
echo "OS $operatingsystem ($architecture)"
echo "Running on $requested_NumCPU $processortype."
echo "Calculation $inputfile and $commandfile from $PWD."
echo "Working directry is \$PBS_O_WORKDIR"
cd \$PBS_O_WORKDIR

export PATH="\$PATH:$Multiwfnpath"
export Multiwfnpath="$Multiwfnpath"
export LD_LIBRARY_PATH="\$LD_LIBRARY_PATH:$Multiwfnpath"
export KMP_STACKSIZE=$requested_KMP_STACKSIZE

date
Multiwfn "$inputfile" < "$commandfile" > "$outputfile"
date

EOF

message "Created submit PBS script, to start the job:"
message "  qsub $submitscript"

exit 0
}



#
# Evaluate Options
#

settings "$@"
setLoggingOptions
checkAndSetMemory
checkAndSetMultiWFN
checkLocalSettinsIni

[[ "$execmode" == "remote" ]] && runRemote

runInteractive

message "Thank you for travelling with $scriptname."
exit 0

