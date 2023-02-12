# Installing and using a local, disposable ToolFactory development server.

### tl;dr

The ToolFactory is a *form driven XML generator*, designed for developers who write their own scripts.

 * It creates an ordinary, shareable Galaxy tool that runs the supplied script and designated Conda dependencies.
 * The generated tool XML is defined by elements added to the ToolFactory form.
 * The generated tool form has all the defined text prompts, parameter settings, and input data selectors.
 * Generated tools are functionally equivalent and as secure as simple hand written XML.
 * The XML document is built from the form settings, with a [specialised XML parser](https://github.com/hexylena/galaxyxml).

New Galaxy tools are best made by an experienced developer using [specialised development methods](https://training.galaxyproject.org/training-material/topics/dev/tutorials/tool-from-scratch/tutorial.html).
All developers are encouraged to learn those skills, but until they are available, the ToolFactory can turn any simple working, command line driven script
with test data and a handful of parameters, into a normal, shareable Galaxy tool. If it has hundreds of parameters or needs specialised XML, it will
require an experienced developer with appropriate tools.

### Basic idea

The ToolFactory generates tool XML based on settings on a Galaxy tool form, installs it and tests it using the supplied test data, then packages it up as a Toolshed ready archive,
with that test built in.

Automated XML is very limited and inflexible, but it can be useful for simple tools when experienced Galaxy tool developers
are not readily available. When a tool is generated, it is written, installed and tested by the ToolFactory job.
Jobs run in 10-20 seconds plus the time to install any new dependencies. A browser screen refresh is needed to reload the tool panel to see and start using the newly installed tool.

Even using an automated generator, planning and preparation are the key to efficiently creating a useful tool. Debugging the script in the ToolFactory
is very clumsy. Get it right first, then build the new tool knowing that any defects are likely from the way the form is configured, not the script, test data or dependencies.

### Different approaches for building simple tools are illustrated by the examples

A handy way to see how the ToolFactory works is to use Galaxy's inbuilt redo ⭮ button for any interesting example Toolshed archive outputs
in the default starting history. The form settings that created that tool will be restored, ready for experimenting with your own scripts.

For example, if you have a Python script, there are argparse and positional parameter passing examples.
Argparse is far less prone to accidentally mixed up parameters than positional parameters.

Shell script models include a tac|rev and Hello examples. Trivial, but versatile models for potentially more complicated and useful tools.
Tacrev is the simplest filter tool model using STDIN and STDOUT to really reverse a text file selected as an input.
Hello demostrates a user supplied parameter in a bash script for a string sent to STDOUT that appears as a new file in the history.

Any Conda interpreter can be used. Perl, Lisp and Prolog examples demonstrate external (Lisp) and inbuilt script models.
The Rscript Plotter example illustrates parameter passing to R and presenting arbitrary plots or other script outputs as history collections.
Selects and repeats are available for new tool form parameters, and any tool can return collections where there are multiple informational outputs that are
not needed individually for downstream processing such as workflows.

In addition to scripting interpreters, any Conda dependencies, such as BWA and samtools can be loaded for your script or an ordinary command line as the BWA examples show.

### Building your own tools.

Start out with a working script. It might be open source or your own.
The important thing is that it works correctly on the command line with some small sample data inputs and specific parameter settings.
*Do not try to debug your script* using the ToolFactory, because it is a very inefficient way to do something more easily done in a shell session.
If there are complications in parameter passing, it may sometimes be necessary to adjust the way the script accepts parameters, to suit the simple ToolFactory
XML code generator.

All the working sample data sets must be uploaded into a Galaxy history, ready to select on the ToolFactory form as input data for the test, before you can build a new tool.

Decide on a model for the tool. Simple filters are easy, but typically, a model with a few specific format input files, and a few specific format output files, with or without a script, and with a few
user chosen parameter settings, will work for many simple tool needs.

Details are supplied on the form for each of the elements needed for the new tool. These include:

 * An optional working script to paste into a text box. It is not suitable for *editing* the script as part of tool development.
 * Dependencies such as bash/Python/R/Lisp/BWA/samtools... or anything else available in Conda
 * Input sample files uploaded in the history so they can be selected when defining input files, and used for the tool test.
 * Output files that will appear in the history when the new tool is run.
 * User-controlled command line parameters.
 * Command line construction and how parameters are passed to the script or dependency.

Named parameters such as argparser uses are safer as complexity grows.

 Many of these require related specific details such as:

  * an internal parameter name
  * a form or file parameter type
  * optional default value
  * user form prompt and help text

to prepare the ToolFactory form to build your new tool and test it with the supplied input data samples.

The new generated tool is installed in the local tools section, but will need a screen refresh to appear.
It can be used like any other tool and will work the way it will work when installed into any Galaxy server.

The new tool appears as a Toolshed archive file in the history. A collection of tool related files also appears, including a log of the job run.
The archive is ready to upload to a toolshed if it is sufficiently reliable and useful to share.

### Galaxy UI and output features available for generated tools

Input and output files are defined as repeatable form elements. Input files can be user repeatable if the script can handle repeated parameters.

Numeric and text parameters can be used and passed as argparse (--foo) style or in positional order if necessary.

The Repeats example shows an input parameter marked as repeating on the ToolFactory form, to return a run time,
user determined number of repeated parameter values, using Python's argparser.

The select example shows how to build a select parameter into a ToolFactory tool form. Tests will include it.

Collections can handle arbitrary script outputs to a single directory, as shown by the Plotter Rscript example.


### Scope and limitations

If two jobs run Conda at the same time, dependencies may become corrupted, so a designated queue for the ToolFactory runs jobs serially.
All other tools run normally on the local runner.

Reliable tests cannot be automatically generated for tools that create arbitrary collections, since the contents cannot be computed at tool generation time.
A suitable test XML section can be supplied, as the Plotter example shows. A Galaxy form is a clumsy way to write XML.
Better to use the proper developer tools, rather than a limited automated code generator, if you need collection outputs tested or other
hard to generate complications. Conventional development tools are recommended for wrapping complex packages.
The ToolFactory is only useful for relatively simple needs, such as a handful of parameters and i/o files.

Long forms become unpleasant to navigate. In theory they should work, but there are many
things that a very simple minded code generator cannot do.

Implemented as a Galaxy tool in a development Galaxy server, it can speed up the development and testing of
new simple tools, from existing working scripts and/or conda packages. The learning curve is smaller and the scope
is correspondingly limited by the code generator used.

### Local installation and login

#### Do not expose this Galaxy server on the public internet. It is not secured.

All the usual layers of isolation required to make a server secure for public exposure, are missing as installed.
It's easy and safe to run locally, so installation on any public server is strongly discouraged.

The ToolFactory code *relies* on the default server's *lack of isolation*.
In any properly secured server, a running tool is unable to install, configure and test newly generated tools!
This is convenient and safe in a local disposable development server, but unsafe if exposed to hostile miscreants.
The ToolFactory will only execute for administrative users. Ordinary and anonymous users can fill in the form, but it will be a waste of time as execution will
throw an error before a tool is generated. Generated tools are ordinary Galaxy tools, so should always be inspected before installation from an untrusted source.

#### ToolFactory development server installation script

Run the shell script (localtf.sh) included with this repository. Sudo will be needed multiple times. It will download and configure a development server with the ToolFactory installed.

The steps are:

 * Download and unpack a zip of (default) 23.0 which is working well as at February 2023, or perhaps a stable 22.05 release - edit localtf.sh to suit.
 * Install the ToolFactory configuration overlay
 * Create the default admin user and insert the API keys in various ToolFactory scripts.
 * Upload the default history and a workflow to build the examples.

This takes some time - 15-20 minutes or so, to complete.
A functioning development server will weigh in at 8GB or so, so be sure your hard drive has plenty of room.
It is all based in a single directory, *galaxytf* created wherever it is run from. That directory can be removed when no longer needed.

Rerunning the script will destroy the database and jobs directory to create a clean new installation. It should only need to be run once in the life
of the development server.

#### Starting, using and stopping the server after installation

Once installation is complete:
 * start the server from the *galaxytf* directory with *sh run.sh*. The logs will be displayed.
 * ^c (control+c) will stop it from the console.
 * In routine use, the *--daemon* and *--stop-daemon* flags for run.sh can be used to start and stop the server in the background.

The server should be ready in 30 seconds or less, at *http://localhost:8080*.
Initial login as admin using *toolfactory@galaxy.org* with password *ChangeMe!* which of course you should change!

.. figure:: https://galaxyproject.org/images/galaxy-logos/galaxy_project_logo.jpg
   :alt: Galaxy Logo

The latest information about Galaxy can be found on the `Galaxy Community Hub <https://galaxyproject.org/>`__.

