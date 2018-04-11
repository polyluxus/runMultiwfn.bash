# runMultiwfn.bash

A wrapper for Multiwfn 3.4.1 (Linux) written in bash.

It does probably work without any modification for any newer
version; as long as the definitions of the environment variables 
did/do not change.
Since version 0.5.0 the legacy mode has been removed.
If really necessary, use an older version of this script with
a more complicated installation procedure.
In older versions like Multiwfn 3.3.8, 
an additional library had to be made available.
(This was becomming too hard to maintain.)  
Detailed instructions how to unpack and install Multiwfn in
oder to use this script effectively can be found in a separate
file INSTALL.txt 

This 'software' comes with absolutely no warrenty. None. Nada.
You can (and should) modify the script for improvements
or to adapt it to your needs. If you do, I would be grateful 
for a little note.  
If you find any bugs, I appreciate a note, too.

Enjoy working with this piece of code.

---

## How to use

Requires Bash-4.2.1 (probably, that is what I tested) and 
for the interactive sessions it uses `script` from
the util-linux-ng package to also log the keystrokes.

After appropriate modifications of the paths of Multiwfn,
it can simply be called with

```
path/to/runMultiwfn.sh [otions] [IPUT_FILE]
```

If started without any argument, it is fully interactive 
and uses the defaults.

---

## Variables and Options

The following section contains a more detailed overview
of the options that can be supplied to the script.

The script will (or might) attempt to read variables necessary for
the execution of MultiWFN from the environment settings.
For one reason or another, you might have already installed 
this program, or set the variables differently.
Then it will only provide the possibility to easier log the 
output of the program.
If they are unset, they will be replaced by default values
or they can be specified via option switches,
or they can be controlled by the rc file.

The following option switches are available:
 
  - `-m <ARG>`
       Define memory to be used per thread in byte.
       This basically means setting the environment
       variable `KMP_STACKSIZE`.
       The procedure outlined in the Multiwfn manual
       is not recommended. See INSTALL.txt
       The default value if nothing is specified is the
       recommended value of 64000000 byte.

  - `-p <ARG>`
       Define number of threads to be used.
       If not set via this switch, a default of 4 threads
       is assumed, or whatever is set through the environment or rc.

  - `-l <ARG>`
       Legacy mode (deprecated): Request different version.
       This option has no effect any more, since all code 
       relating to it has been removed.
       If you really need it, you have to work with an older
       version of this script, too. Sorry.

  - `-g`
       Run without GUI.
       MultiWFN provides a precompiled version without the 
       graphical user interface. This might be very convenient
       if it is operated in an automated fashion.  

  - `-q`
       Supress creating a logfile.
       By default a logfile will be created in the 
       location of execution with the base name of the
       specified inputscript extended by the base name of this
       script and the ending 'out'.
       If such a file exists, then a backup copy of the old
       file will be created.

  - `-o <ARG>` 
       Specify outputfile.
       If you desire you can specify any location, 
       where the logfile should be saved. If you do 
       so, then you should know that any existing file
       will be overwritten.

  - `-i <ARG>`
       Specify ithe file on which MultiWFN should operate.
       These are the files that are supported by
       MultiWFN as described in section 2.5 of the program manual.
       The script will check if the inputfile exists
       and is readable. It will abort if neither.
       This switch can be omitted if you supply the 
       file as the last argument, thus
       `runMultiwfn [opts] <file>` is the same as
       `runMultiwfn [opts] -i <file>`.
       If specified more than once, the program will abort. 

  - `-c <ARG>`
       Specify a file, that contains a sequence of 
       numbers, that can be interpreted by MultiWFN.
       The basic idea is to use the program non-interactively. 
       As far as I know the supplied file shall only contain numbers,
       and it might contain comments.
       There are examples available.
       The script will check if the commandfile exists
       and is readable. It will abort if neither.

  - `-f`
       Force to use supplied values (or defaults).
       This will overwrite any environment variable.
       Use with great care.
       Really, use with great care. If variables have 
       already been set, then there is a reason. This
       could have various reasons. Overwriting them 
       might cause failure.  
       I am not sure anymore if this works as intended in version
       0.5.0 of this script.

  - `-k`
       Keep temporarily created `settings.ini`.

  - `-Q <ARG>`
       Which type of job script should be produced.
       Arguments currently implemented: pbs-gen, bsub-rwth.
       Mandatory for remote execution, can be set in rc.

  - `-P <ARG>`
       Account to project.
       Automatically selects '-Q bsub-rwth' and remote execution.

  - `-s`
       Suppress logging messages of the script.
       (May be specified multiple times.)

  - `h`
       Prints a short version of the options.

---

## Examples

The examples folder contains a few files generated with Gaussian 09, 
that demonstrate some of the functionality of the script.  
It also contains a slightly modified version of `settings.ini`,
which you might want to further modify and copy to the base 
directory of the script.
See INSTALL.txt for further information.
To Do: Provide some more wfn files for some more elements and methods.

---

## Who wrote this?

Martin - that is me \\(^-^)/
Complaints can be directed through the chat 'The Periodic Table'
somewhere at https://chemistry.stackexchange.com,
or via github (polyluxus), or any other way you can think of.
I have a blog (that has not been updated in a while): 
https://thedailystamp.wordpress.com/

(Martin; 0.5.0; 2018-04-11)
