# runMultiwfn.bash
A wrapper for Multiwfn (Linux) written in bash.

This is the readme.txt accompanying runMultiwfn.sh. (Before I decided to use github.)

The script is a wrapper intended for MultiWFN 3.4.1 (linux).
It does probably work without any modification for any other 
version, as long as the definitions of the environment variables 
did/do not change.
Detailed instructions what kind of installation of MultiWFN is 
necessary for this script to work can be found at the end.

This software comes with absolutely no warrenty. None. Nada.
You can (and should) modify the script for improvements
or to adapt it to your needs. If you do, I would be grateful 
for a little note.
If you find any bugs, I appreciate a note, too.

Enjoy working with this piece of code.

---
This readme.txt accompanies

VERSION    :   0.4.2
DATE       :   2017-12-13

USAGE      :   runMultiwfn.sh [otions] [IPUT_FILE]

---

The following section contains a more detailed overview
of the options that can be supplied to the script.

VARIABLES  :

The script will attempt to read variables necessary for
the execution of MultiWFN from the environment settings.
For one reason or another, you might have already installed 
this program, or set the variables differently.
Then it will only provide the possibility to easier log the 
output of the program.
If they are unset, they will be replaced by default values
or they can be specified via option switches.

OPTIONS    :
 
  -m <ARG> Define memory to be used per thread in byte.
           This basically means setting the environment
           variable KMP_STACKSIZE.
           The procedure outlined in the Multiwfn manual
           is not recommended. See below.
           The default value if nothing is specified is the
           recommended value of 64000000 byte.

  -p <ARG> Define number of threads to be used.
           This switch only works correctly if you follow 
           the instructions below on how to install the 
           program package.
           If no value is provided, a default of 2 threads
           is assumed, or whatever is set though the environment.

  -l <ARG> Legacy mode: Request different version.
           Theoretically one can have multiple versions installed 
           parallel, and might keep one or the other for testing 
           purpose. Previous versions (<3.4.0) required that 
           LD_LIBRARY_PATH is set.
           In principle you can enter whatever you want here, it 
           should work as long as the set-up is similar to the one 
           outlined below. However, use with great care.
           This option has no effect if the version is set through 
           an environment variable.

  -g       run without GUI.
           MultiWFN provides a precompiled version without the 
           graphical user interface. This might be very convenient
           if it is operated in an automated fashion.  
           See below for installation instructions.

  -q       Supress creating a logfile.
           By default a logfile will be created in the 
           location of execution with the base name of the
           specified inputscript extended by the base name of this
           script and the ending "out".
           If such a file exists, then a backup copy of the old
           file will be created.

  -o <ARG> Specify outputfile.
           If you desire you can specify any location, 
           where the logfile should be saved. If you do 
           so, then you should know that any existing file
           will be overwritten.

  -i <ARG> Specify file on which MultiWFN should operate.
           These are the files that are supported by
           MultiWFN as described in section 2.5 of the
           program manual.
           The script will check if the inputfile exists
           and is readable. It will abort if neither.
           This switch can be omitted if you supply the 
           file as the last argument, thus
             -> runMultiwfn [opts] <file>
           is the same as
             -> runMultiwfn [opts] -i <file>
           If specified more than once, the program will
           abort. 

  -c <ARG> Specify a file, that contains a sequence of 
           numbers, that can be interpreted by MultiWFN.
           (I am still trying to figure this one out
            myself. I will update this as soon as 
            possible.                               )
           The basic idea is to use the program non-
           interactively. As far as I know the supplied 
           file shall only contain numbers.
           The script will check if the commandfile exists
           and is readable. It will abort if neither.

  -f       Force to use supplied values (or defaults).
           This will overwrite any environment variable.
           Use with great care.
           Really, use with great care. If variables have 
           already been set, then there is a reason. This
           could have various reasons. Overwriting them 
           might cause failure.

  -h       Prints a short version of this file.

---

AUTHOR    : Martin - that is me \(^-^)/
            Complaints via chemistry.stackexchange.com
            or any other way you can think of.
            I have a blog (that has not been updated in a while): 
              https://thedailystamp.wordpress.com/

---

INSTALLATION GUIDE

This is the most important part, because without the 
correct installation and subsequent modification of the 
script itself, it will not work.
I have tried to simplify it as much as possible and I will be
working on it further, but until then see the following.

(a) VARIABLES  :

  The script will attempt to read variables necessary for
  the execution of MultiWFN from the environment settings.
  The reason for that was so that the script could be called 
  by another script which submits it to a scheduler, and the 
  execution is then carried out on via the compute nodes.
  However, I have abandonned this idea. I am working on
  another possibility to integrate this functionality here.

  If variables are unset, they will be replaced by default 
  values or they can be specified via the option switches.

  If you followed the instructions in the Multiwfn manual 
  of an older version, then you might have already set the 
  environment variables
  KMP_STACKSIZE, LD_LIBRARY_PATH, and maybe even
  Multiwfnpath. 
  In the newer versions you would only set
  KMP_STACKSIZE, and Multiwfnpath. 
  This needs to be undone.
  If you have added any of the following lines to your 
  bashrc, then they need to be removed. We assume for a
  moment, that we unpacked the program to the path
  ~/sub/Multiwfn, so the bashrc probably contains these
  lines:
    export KMP_STACKSIZE=64000000
    export Multiwfnpath=~/sob/Multiwfn
  And in older versions also
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/sob/Multiwfn
  Delete them. Otherwise the script will always read 
  these values and use them. Then there is no point in 
  using this script it in the first place.

(b) Unpacking
  I personally like to have a seperate user for any
  chemistry related software. This is not necessary. But
  it keeps the pathnames a little shorter. On my system
  the user is called "chemsoft". This is the home:
    /home/chemsoft/

  You can uncompress the original script to any location
  that suits you. Note that you need a second level for 
  the purpose of using different "settings.ini" 
  This is the culprit, but I found this workaround easier
  than anything else (so far).
  For the purpose of this manual we use the sample user
  "chemsoft" and we uncompress to the following path
    /home/chemsoft/multiwfn/Multiwfn_3.4.1_bin_Linux

  After that we create the following directories:
    /home/chemsoft/multiwfn/Multiwfn_3.4.1_cpu1
    /home/chemsoft/multiwfn/Multiwfn_3.4.1_cpu2
    /home/chemsoft/multiwfn/Multiwfn_3.4.1_cpu4
    /home/chemsoft/multiwfn/Multiwfn_3.4.1_cpu8
    /home/chemsoft/multiwfn/Multiwfn_3.4.1_cpu10

  In each of the directories we need to create the
  symbolic links to the executeable:
    ln -s ../Multiwfn_3.3.8_bin_Linux/Multiwfn
  For older versions also the library:
    ln -s ../Multiwfn_3.3.8_bin_Linux/libiomp5.so
  You can also add a link to the examples
    ln -s ../Multiwfn_3.3.8_bin_Linux/examples/

  The only file that will be different is the file that
  contains the settings for MultiWFN:
    settings.ini
  
  For this to work correctly, you need to modify the
  line responsible for the number of threads.
  For the cpu1 case it should read like this:
    nthreads= 1 //How many threads [...]
  And so on for cpu2, cpu4, etc. ...
  Before doing anything, the script will check if the requested 
  directory exists. You can therefore have as many different 
  cases as you like.
  It depends on the number of processors you have available, 
  or that you are willing to use for the calculation. 
  I recommend procedures to a maximum of
  half the number of cores per node you have.

(c) Non-GUI versions
  If you want to use the version without the GUI (and maybe want to
  switch) you have to do the same as above for that version.
  These binaries should be located in 
    /home/chemsoft/multiwfn/Multiwfn_3.4.1ng_cpu1
  and other cases.
  Additionally you need to enable that mode, see below.

(d) Modifying the script
  The last thing you need to do is edit the script itself.
  I have simplified the procedure and there is a very
  short summary in the script itself.
  You need to set a few variables so that the script is able to 
  find the binaries. There are a few variables that need changing.
  If you followed exactly the example above, then you might already 
  be good to go. 
  IF not, you need to modify the following line:
   installPathMultiWFN="/home/chemsoft/multiwfn"
  This variable needs to contain the path to the directory,
  which contains the directories with the different set-ups.
  The next line you need to change is the following:
   installPrefixMultiWFN="Multiwfn_"
  to whatever you have chosen your directory structure to be.
  Next is the version number you are using:
   installVersionMultiWFN="3.4.1"
  Lastly the suffix that determines the number of cpus
   installSuffixMultiWFN="_cpu"
  You can also choose the default number of cpu there
   requested_NumCPU=2

  That should basically all jumbled together reproduce the full path
  of the executables.

  If you want to use the non-GUI version, you have to enable it:
   installNoguiMultiWFN="yes"
  The 'ng' part is currently still hardcoded.

  The script will not check if there is an executeable, or 
  settings.ini. It only checks the pathname.

(e) Where does this script go? 
  In principle you can place it anywhere you like.
  I recommend choosing 
   /home/chemsoft/multiwfn

  Make sure it is executeable.
   (chmod +x <scriptname>)

  Now everything should be done.

(e) Optional

  You can create a softlink link in your personal ~/bin 
  directory for easier access. This is of course provided 
  that your ~/bin is part of $PATH.
  Alternatively you can add an alias, or add the multiwfn
  directory to your PATH.

---

VERSIONLOG

0.4.x 2017-12-13
  I rewrote most of the procedures choosing the binary and 
  updated a few other routines to a more elegant code (I hope).
  I abandon the idea for submultiwfn. 
  Instead the next version will contain a subroutine to write a script, 
  that can be submitted to a scheduler.
  (This is basically already done, but I modified the wrong version.)

0.3(alpha) planned features
  Further simplification of the installation process.
  Maybe write a script that automagically configures the 
  script.
  Or even better, analyze the binaries and create an
  auxiliary file, that make modifying the script unnecessary.
  Extend the functionality of this script with the 
    submultiwfn 
  script, that non-interactively runs the program on the 
  compute nodes (through a PBS scheduler).
  This should be linked, so that redundant checks will not
  be performed.
  I'd like to add the possibility to add more customised 
  settings to the binary paths.

0.2(alpha) 2016-02-08
  A slightly easier routine to set up the binaries. It now 
  requires less tweaking of the script.

0.1(alpha)
  The first working draft of the script.

---

This is the last line of this file.
