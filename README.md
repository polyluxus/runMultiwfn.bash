# runMultiwfn.bash

A wrapper for Multiwfn (Linux) written in bash.
Tested with version 3.4.1, and also with 3.5, and currently 3.6.

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
the `util-linux-ng` package to also log the keystrokes.

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

  - `-w <ARG>`
       Define the maximum walltime for remote execution in 
       format `[[HH:]MM:]SS`.
       The default is `24:00:00`, which is probably too long for
       most purposes.

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

  - `-h`
       Prints a short version of the options.

  - `-H`
       Displays the manual (if installed, see INSTALL.txt).
       This requires a pdfviewer installed, which can be set in the rc.
       The script will test a few commands before giving up (see the
       example `runMultiwfn.rc` for details). 

---

## Examples

The examples folder contains a few files generated with Gaussian 09, 
that demonstrate some of the functionality of the script.  
Please note that these examples have not been updated to any changes
in newer (> 3.4.1) versions of Multiwfn and might not work anymore
due to interface changes. 
Please check these files carefully before using them.
It also contains a slightly modified version of `settings.ini`,
which was applicable to version 3.5 of Multiwfn.
There have been significant changes in version 3.6, 
it would be best to obtain this settings file from the original distribution.
A copy of `settings.ini` found in the base directory of the script
will serve as a template for all runs with this script.  .
See INSTALL.txt for further information.

---

## License (GNU General Public License v3.0)

runMultiwn.sh - a wrapper script for Multiwfn  
Copyright (C) 2019 Martin C Schwarzer

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See [LICENSE](LICENSE.txt) to see the full text.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

## Who wrote this?

Martin - that is me \\(^-^)/
Bug reports, suggestions, complaints can be directed 
via the github issue system (polyluxus):
https://github.com/polyluxus/runMultiwfn.bash/issues

(Martin; 0.6.0; 2019-09-10)
