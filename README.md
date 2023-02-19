# A local, disposable ToolFactory development server.

##  Turn scripts into Galaxy tools!

Using the ToolFactory pre-installed in this handy Galaxy development server.

##  Intended users

Scientists who routinely write and test their own scripts for analyses, who would like to use them in Galaxy workflows, but do not yet have the skills required to their own tools

## Summary

The ToolFactory is a Galaxy tool, with an automated *XML code generator*, that converts *working* scripts and Conda dependencies, into ordinary Galaxy tools.

 * It loads and runs like an ordinary Galaxy tool but only runs for a server administrator.
     * See below for details - in particular, *do not* expose on a public server
 * It creates an ordinary Galaxy tool with designated Conda dependencies and user controlled command line parameters, with an optional built in script.
 * The new tool is defined by elements defined on the ToolFactory form.
 * The generated tool has normal form elements, including help text, prompts, input parameters and history input data selectors.
 * The new tool is immediately installed in the development server, ready to use.
 * It will work exactly as the user will see it wherever it is installed.
 * Generated tools are functionally equivalent and as secure as simple hand written XML.
 * The XML wrapper document is automatically generated from the form settings, by a [specialised XML parser](https://github.com/hexylena/galaxyxml).
 * Test inputs and settings supplied at tool generation are used as the built in tool test.



### Basic idea

The ToolFactory generates tool XML based on settings on a Galaxy tool form, installs it and tests it using the supplied test data, then packages it up as a Toolshed ready archive,
with the test built in.

Automated XML is very limited and inflexible, but it can be useful for simple tools, when developers with Galaxy tool development skills are not readily available.
When a tool is generated, it is written, installed and tested and returned to the history. Jobs run in 10-20 seconds plus time needed for Conda to install any new dependencies.
A browser screen refresh is needed to reload the tool panel to see and start using the newly installed tool.

Many Galaxy tool wrappers need to be made by an experienced developer using [specialised development methods](https://training.galaxyproject.org/training-material/topics/dev/tutorials/tool-from-scratch/tutorial.html).
All developers are encouraged to learn those skills.

Where they are not readily available, the ToolFactory provides a very simple XML generator, capable of generating simple tools.
Filling in a form can turn a simple, working command line driven script, that has some small test data samples, and a handful of  parameters, into an ordinary, shareable Galaxy tool.

Even using an automated generator, planning and preparation are the key to efficiently creating a useful tool. Debugging the script in the ToolFactory
is very clumsy. Get it right first, then build the new tool knowing that any defects are likely from the way the form is configured, not the script, test data or dependencies.

### Different approaches for building simple tools are illustrated by the examples

A convenient way to see how the ToolFactory works is to use Galaxy's inbuilt redo ⭮ button for any interesting example outputs
in the default starting history. The form settings that created that tool will be restored, ready for experimenting with your own scripts.

For example, there are argparse and positional parameter passing examples for Python.
Argparse is far less prone to accidentally mixed up parameters than positional parameters.

Shell script models include a tac|rev and Hello examples. Trivial, but versatile models for potentially more complicated and useful tools.
Tacrev is the simplest filter tool model using STDIN and STDOUT to really reverse a text file selected as an input.
Hello demostrates a user supplied parameter in a bash script for a string sent to STDOUT that appears as a new file in the history.

Any Conda interpreter can be used. Perl, Lisp and Prolog examples demonstrate user-supplied (Lisp) and inbuilt (Prolog, Perl) script models.
The Rscript Plotter example illustrates parameter passing to R, and presenting arbitrary plots or other script outputs as history collections.
Selects and repeats are available for new tool form parameters, and any tool can return collections where there are multiple informational outputs that are
not needed individually for downstream processing.

In addition to scripting interpreters, any Conda dependencies, such as BWA and samtools can be loaded for your script or an over-ridden command line as the BWA examples show.


### Building your own tools.

Start out with a script that works correctly on a command line with associated packages and dependency versions for Conda.
It might be an open source package, or your own Python or shell script. Working means correctly processing some small but realistic test data inputs.

If the script works correctly on the command line with those Conda dependencies, some small sample data inputs, and specific command line parameter settings,
it should work correctly as a new tool, provided the inputs and parameters match. The ToolFactory form allows those to be adjusted easily if you "redo" an existing
tool generation job in your history.

*Do not try to debug your script* using the ToolFactory, because it is a very inefficient way to do something more easily done in a shell session.

If there are complications in the way the script requires parameter passed that the ToolFactory cannot satisfy, it may sometimes be possible to adjust the script, to suit the simple ToolFactory
XML code generator. Otherwise it will need an experienced developer and the usual tools.

Upload all the test data samples into a Galaxy history, ready to select on the ToolFactory form as each input field is added to the form to provide data for the test run.
The tool *cannot only be tested and built* if they are supplied.

The ToolFactory offers some common models for useful analysis tools and filters to use in workflows.
Simple *filters* taking STDIN and writing to STDOUT like the tac|rev example, are easy and quick to create.

For many common requirements, the command line driven model, with Conda packages, with or without a supplied script, can usually be adapted.
Tools can take any number of user chosen input files from the history, and parameters set on the tool form at run time.
Output files can be written as new history items for downstream analyses, or as a collection.

Details are supplied on the form for each of the elements needed for the new tool. These include:

 * An optional working script to paste into a text box. It is not suitable for *editing* the script as part of tool development.
 * Dependencies with versions  such as Python/R/Lisp/BWA/samtools... or anything else available in Conda.
 * Input sample files uploaded in the history so they can be selected when defining input files, and used for the tool test.
 * Output files that will appear in the history when the new tool is run.
 * User-controlled command line parameters.
 * Command line construction and how parameters are passed to the script or dependency.

 Many of these require related specific details such as:

  * an internal parameter name
  * a form or file parameter type
  * optional default value
  * user form prompt and help text
  * citations

to prepare the ToolFactory form to build your new tool and test it with the supplied input data samples.

The new generated tool is installed in the local tools section, but will need a screen refresh to appear.
Dependencies will already be installed, so it can be used like any other tool and will work the way it will work when installed into any Galaxy server.

The new tool is installed in the Local Tools menu, ready to try out. Seeing the generated form will often make it possible to make adjustments
so it's easier to use. The "redo" button recreates the ToolFactory form, ready to adjust and rerun. If the tool ID is not changed, the old version will
be overwritten.

A collection of tool related files also appears in the history, including a log of the tool test and job run.
The archive is ready to upload to a toolshed if it is reliable, generalisable, well documented, and useful enough to share.

### Galaxy UI and output features available for generated tools

Input files and parameters can be defined as repeatable form elements, if the script or conda dependency is designed to handle
repeated parameters such as argparser does. Repeated output history files are not available, but a collection is usually a
convenient workaround for outputs not needed downstream as the Plotter example shows.

Numeric and text parameters can be used and passed as argparse (--foo) style or in positional order if necessary.

The Repeats example configures an input text parameter as repeating, so the new tool form allows the user to create any number
of text strings that are concatenated and returned at run time as a text file, as shown in the example script, using Python's argparser.

The select example shows how to build a select parameter into a ToolFactory tool form. Tests will include it.

Collections can handle arbitrary script outputs to a single directory, as shown by the Plotter Rscript example.

All the input example features can be mixed to build the form needed for a new simple tool.

Supplied inputs and the default parameter values are used to construct a test for the tool. If the test fails, the tool will
not build properly. This should never happen because of errors in the script, if it is already know to work properly with the same inputs
on the command line. Clues can be found in the run log if available, or the information (i) and bug pages.

### Scope and limitations

Sqlite works fine. Postgres is more reliable and seems faster but sqlite out of the box seems stable and useable.

If multiple Conda jobs run the same time, processes can spin endlessly or dependencies may become corrupted, so job_conf.yml specifies a queue for the ToolFactory
that only runs jobs serially. All other tools run normally on the local runner.

Reliable tests cannot be automatically generated for tools that create arbitrary collections, since the contents are not yet available at tool generation time.
They do appear after the test so send code - PR please if you care. A suitable test XML section can be supplied, as the Plotter example shows, but really, a Galaxy form
is a clumsy way to write XML. Better to use the proper developer tools, rather than a limited automated code generator, if you need collection outputs tested or other
hard to generate complications. Conventional development tools are recommended for wrapping complex packages.
The ToolFactory is only capable of meeting relatively simple needs, such as a handful of straightforward parameters and i/o files.

Long forms become unpleasant to navigate. In theory they should work, but clearly there will be many things that a simple XML
parser and document generator cannot do.

Implemented as a Galaxy tool in a development Galaxy server, it can speed up the development and testing of
new simple tools, from existing working scripts and/or conda packages. The learning curve is smaller and the scope
is correspondingly limited by the code generator used. Those limitations can be worked around in some situations,
by changing the way the script expects parameters, but an experienced tool developer is probably the best choice at that point...

### Local installation and login

#### Do not expose this Galaxy server on the public internet. It is not secured.

All the usual layers of isolation required to make a server secure for public exposure, are missing as installed.
It's easy and safe to run locally, so installation on any public server is strongly discouraged.

The ToolFactory code *relies* on the default server's *lack of isolation*.
In any properly secured server, a running tool is unable to install, configure and test newly generated tools, but
that's exactly what the ToolFactory tool does. This is convenient and safe in a local disposable development server, but unsafe if exposed to hostile miscreants.
There is an important protection - *the ToolFactory will only work for administrative users*.
Ordinary and anonymous users can fill in the form, but it will be a waste of time, because tool execution exit with an error before a tool is generated.

Generated tools are ordinary Galaxy tools.
They should always be inspected before installation from an untrusted source.

#### ToolFactory development server installation script

Run the shell script (localtf.sh) included with this repository. Sudo will be needed multiple times.

It will download and configure a development server with the ToolFactory installed, by doing these things:

 * Download and unpack a zip of (default) 23.0 which is working well as at February 2023, or perhaps a stable 22.05 release - edit localtf.sh to suit.
 * Build the client (slow) and prepare a new sqlite database (replacing any old one!)
 * Install the ToolFactory configuration overlay
 * Create the default admin user and insert the API keys in various ToolFactory scripts.
 * Upload the default history and a workflow to build the examples.

This takes some time - 15-20 minutes or so, to complete.
A functioning development server will weigh in at 8GB or so of disk space, so be sure your hard drive has plenty of room.
It is all based in a single directory, *galaxytf* created as ../galaxytf from the cloned repository root where the script should be run.

Rerunning the script will *destroy the entire galaxytf directory* - all ~8GB, and create a clean new installation.
It should only need to be run once in the life of the development server.

Remove the *galaxytf* directory to remove the entire development server when it is no longer needed. Save all your tools and histories,
because the jobs in a history can be used to update a tool easily, and a history can be imported into a fresh development instance
when needed.

#### Starting, using and stopping the server after installation

Once installation is complete:
 * start the server from the *galaxytf* directory with *sh run.sh*. The logs will be displayed.
 * ^c (control+c) will stop it from the console.
 * In routine use, add the *--daemon* and *--stop-daemon* flags to run.sh, to start and stop the server in the background respectively.
 * In 23.0 that is equivalent to *venv/bin/galaxyctl start* and *venv/bin/galaxyctl stop*.

The server should be ready in 30 seconds or less, at *http://localhost:8080*.
Initial login as admin using *toolfactory@galaxy.org* with password *ChangeMe!* which of course you should change!

.. figure:: https://galaxyproject.org/images/galaxy-logos/galaxy_project_logo.jpg
   :alt: Galaxy Logo

The latest information about Galaxy can be found on the `Galaxy Community Hub <https://galaxyproject.org/>`__.
