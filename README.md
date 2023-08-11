# Build a local, disposable ToolFactory development server.

## See the introductory tutorial at https://training.galaxyproject.org/training-material/topics/dev/tutorials/tool-generators/tutorial.html

Clone the latest Galaxy server code and install a configuration overlay, allowing your new development server to
*turn scripts into shareable Galaxy tools*.

## Update August 2023:
Two recent examples of useful ToolFactory generated tool generation jobs are included in an uploaded administrator history ready to re-run and adjust as needed. They wrap plotly.express and are described at https://lazarus.name/demo/. They are available for server installation from the Galaxy Toolshed:

![plotly_tabular_tool](https://github.com/fubar2/plotly_tabular_tool), a generic and interactive html plot generator suitable for <5k rows of data,
and
![plotly_blast_tool](https://github.com/fubar2/plotly_blast_tool), a customised version for blast search 25 column Galaxy tabular outputs.

ToolFactory now supports change_format *when* clauses so these two tools allow either png or html interactive outputs. These tools are now
included in the Docker or local ToolFactory instances as an advanced example history and workflow, making it easy to see how they were created
and easy to make revised versions for your own use. For example, the specialised blast version has the header hardwired and
transforms the evalue column as -log10, but is otherwise the same code as the generic
tabular plotter.

##  Triage point

If you are new to Galaxy, and you know that you will be doing a lot of tool development, please do not proceed. We strongly recommend that you spend your time with the [specialised development methods](https://training.galaxyproject.org/training-material/topics/dev/tutorials/tool-from-scratch/tutorial.html) training material for the supported tool chain infrastructure and practices. In the long run, it will be time well spent. 

The ToolFactory is an automated code generator. It can only deal with a small subset of uncomplicated tool building tasks. It is potentially useful for those with relatively modest tool building requirements. Converting locally developed scripts into ordinary Galaxy tools is one of the main use-cases. Where difficulties arise, tweaks to the script i/o may allow the simple automated code generator to wrap it. Learning to use the ToolFactory may be a useful and correspondingly modest investment of effort.

## Installation and very quick start instructions (see below for a local *persistent* non-docker installation)

### Docker image - without persistence

The docker image created from the Dockerfile in this repository is the quickest and easiest way to get the ToolFactory working.
Be warned that all work is lost when the container is stopped - nothing is persistent.
Any useful artifacts such as work done in a new history or new tool tarballs must be exported and saved before shutting down.

```
docker pull quay.io/fubar2/galaxy_toolfactory:latest
docker run -d -p 8080:8080 quay.io/fubar2/galaxy_toolfactory:latest
```

After starting the new image, watch the docker container logs until gunicorn is ready to serve, or wait
about 20-30 seconds, then browse to [http://localhost:8080](http://localhost:8080)
If a Galaxy server appears, proceed with the login instructions above and you should see a history containing all the example tools.

Only an administrator can execute the ToolFactory. The default email is "toolfactory@galaxy.org" and the password is "ChangeMe!"

## Basic idea
The ToolFactory is a Galaxy tool, with an automated *XML code generator*, that converts *working* scripts and Conda dependencies, into ordinary Galaxy tools.

 * Tools created by the ToolFactory are ordinary, secure, shareable Galaxy tools.
 * The new tool is defined by elements added to the ToolFactory form and is generated when the ToolFactory is executed.
 * The generated tool has a typical form with the supplied help text, prompts, input parameters and history input data selector elements.
 * The new tool is installed in the development server, ready to use.
 * It will work exactly as the user will see it wherever it is installed from the Toolshed.
 * The XML wrapper document is generated from the form settings, using a [specialised XML parser](https://github.com/hexylena/galaxyxml).https://lazarus.name/demo/
 * Data inputs and parameter settings supplied on the ToolFactory form, are used as the built-in tool test.
 * Tools need to be installed in a well managed Galaxy server to be useful for research, but they are ready to run.

It uses an automated code generator, so there are many requirements it will not be able to satisfy. ChatGPT it is not.

Conditional parameters, that depend on user choices such as selecting paired or unpaired sequence inputs, are not supported at present.
Those and most other advanced tool features will need an expert developer.
Many useful, simple tools do not need them. Tools requiring them can be split into several separate tools if necessary.
Simple tools are sometimes very useful in complex analyses, so the ToolFactory may offer a solution for researchers lacking the necessary additional Galaxy tool building skills.

The "Hello" tool was generated by filling in a form. That form can be regenerated, by clicking the circular arrow redo button ⭮ on the archive containing the tool, in the default history.
It's a trivial example, but shows how to run any simple bash script, how to interact with the user and how to write a new output file to the history.
This can be easily extended to do more useful things, by adding more complex scripts with more user input parameters.

ToolFactory jobs run in 10-20 seconds plus time needed for the test and for Conda to install any new dependencies in the development server.
A browser screen refresh will be needed, when the job succeeds, to reload the tool panel and start using the newly installed tool.

Even using an automated generator, planning and preparation are essential, to efficiently create a useful tool. Debugging the script in the ToolFactory is very clumsy.
Get it right on the command line first, in a Conda environment. Then upload all the test data into a history and build the new tool. That way, any errors are probably from ToolFactory form configuration, since the script is known to work with that test data, those parameters and those dependencies.

## Simple tool examples as models

The default history for the admin account contains the results of running a workflow (also installed) that generates all the examples.
The most convenient way to see how the ToolFactory works, is to use Galaxy's inbuilt redo ⭮ button for any interesting example outputs
in the default starting history. The form settings that created that tool will be restored, ready for experimenting with your own scripts.

Tool requirements are determined by the requirements of the Conda dependency or the script.
An unlimited number of elements can be added to a form
Most will require one or more input files, with specific datatypes.
Most will require one or more parameters as strings, numbers or selections.
A tool can be built without requiring any user supplied input files or parameters, but every functional tool must create one or more outputs in the history.

There are argparse and positional parameter passing examples for Python. The Repeats example uses argparse and is easily replicated.
Argparse is far less prone to accidentally mixed up parameters than positional parameters.

Shell script models include a tac|rev and Hello examples. Trivial, but versatile models for potentially more complicated and useful tools.
Tacrev is the simplest model, a shell script filter to really reverse a text file selected as an input.
Hello also uses a one line bash script, with a user supplied parameter written to a string, captured as a new file in the history.
The sedtest runs a sed edit string on the chosen input file so is like the IUC tools that allow scripts for specific interpreters.
Recreating the form will show how STDIN and STDOUT can be conveniently used for input and output in simple tasks.

Any Conda interpreter can be used. Perl, Lisp and Prolog examples demonstrate user-supplied (Lisp) and inbuilt (Prolog, Perl) script models.
More broadly, any Conda dependencies, such as BWA and samtools can be loaded for a simple bash script or a developer supplied (*over-ridden*)
XML command line, as the BWA examples demonstrate.

The Plotter example illustrates parameter passing to Rscript, and presenting arbitrary plots or other new outputs as history collections.


## Building your own tools.

Start out with a script that works correctly on a command line with associated packages and dependency versions for Conda.
It might be an open source package, or your own Python or shell script. Working means correctly processing some small but realistic test data inputs.

If the script works correctly on the command line, it should work correctly as a new tool, provided the dependencies, inputs and command line parameters match. The ToolFactory form allows those to be adjusted easily if required, using the "redo"  ⭮ on an existing
job in the history.

*Do not try to debug your script* using the ToolFactory, because it is a very inefficient way to do something more easily done in a shell session.

If there are complications in the way the script requires parameter passed that the ToolFactory cannot satisfy, it may sometimes be possible to adjust the script, to suit the simple ToolFactory XML code generator. This is not possible with any Conda analysis package, so these will usually need an experienced developer and the usual development tools to cope with their complicated command lines. 

Before starting the form, if the tool takes any history input files, upload the working test data samples you already have, into a Galaxy history, ready to select on the
ToolFactory form as each user input history element  is defined
.
These provide data for the test. A tool *cannot be tested and built* if they are not available.

### Common tool patterns

The ToolFactory offers simple *filters* taking STDIN and writing to STDOUT like the tac|rev example. These can use any Conda dependency. Unix utilities can be included as Conda dependencies to ensure that the tool will run, even in execution environments lacking common utilities.

Adding parameters and i/o in a more complicated command line driven model, with Conda packages, with or without a supplied script, covers a large range of common requirements, 
bearing in mind the many limitations of an automated code generator.

Each tool can specify any number of user selected history input files, and user supplied parameters.
Output files can be written as individual new history items for downstream analyses, or mixed together in a collection.

### Information needed for a new tool

Details are supplied on the form for each of the elements needed for the new tool. These include:

 * An optional working script. 
 * Dependencies with versions. Anything available in Conda, such as Python/R/Lisp/BWA/samtools. 
 * Input sample files uploaded in the history, selected when defining input files, and used for the tool test.
 * Output files that will appear in the history when the new tool is run.
 * User-controlled command line parameters.

Many of these involve related choices, including:

  * an internal parameter name
  * a form or file parameter type
  * optional default value
  * user form prompt and help text

 The tool itself has metadata, and other options including:

  * Unique id
  * Command line construction method to pass parameters to the script or dependency.
  * Help text and links
  * Citations

### At job completion

The new generated tool will appear in the *Local tools* section of the tool menu after a screen refresh, when the job has succeeded.
Dependencies will already be installed, so it can be used like any other tool and will work the way it will work when installed into any Galaxy server.

Recreating the same form will make it easy to make adjustments and regenerate the tool with changes or even to generate a different tool.
The "redo" button ⭮ recreates the ToolFactory form, ready to adjust and rerun. If the tool ID is not changed, the old matching one will
be overwritten. Each new tool ID makes a new tool in the Local tools section.

A collection of tool related files also appears in the history, including a log of the tool test and job run.
The archive is ready to upload to a toolshed if it is reliable, generalisable, well documented, and useful enough to share.

Try the new tool to ensure it does what you expect.

### Galaxy UI and output features available for generated tool forms

Input files and parameters can be defined as repeatable form elements, if the script or the target conda dependency can correctly process repeated parameters such as argparser does.

Repeated output history files are not available, but a collection is usually a
convenient workaround for outputs not needed downstream. Use of a collection is illustrated in the Plotter Rscript example.

Select lists, numeric and text parameters can be used in forms.
Their settings can be passed to the dependency or script on the command line as argparse (*--foo*) style or in positional order as necessary.

The Repeats example configures an input text parameter as repeating, so the new tool form allows the user to create any number of different text strings. These are passed to the script, where they are parsed out of the command line with Python's argparser,
concatenated and written to a new text file in the history.

The Select example shows a select parameter, returning the string from the option chosen on the ToolFactory tool form to the history.

Input features can be mixed, to build the form needed for a new simple tool.

Supplied inputs and the default parameter values are used to construct a test for the tool. If the test fails, the tool will not build. This should never happen because of errors in the script, if it is already know to work properly with the same inputs
on the command line. Clues can be found in the run log if available, or the information (i) and bug pages.

## Scope and limitations

Many Galaxy tool wrappers require an experienced developer using [specialised development methods](https://training.galaxyproject.org/training-material/topics/dev/tutorials/tool-from-scratch/tutorial.html).
All developers are encouraged to learn those skills.

Where those skills are not readily available, the ToolFactory provides a simple XML generator, capable of generating simple tools.
Filling in a form can turn a simple, working command line driven script, that has some small test data samples, and a handful of  parameters, into an ordinary, shareable Galaxy tool.
Implemented as a Galaxy tool in a development Galaxy server, it can speed up the development and testing of new simple tools, from existing working
scripts and/or conda packages.

The learning curve is smaller and the scope is correspondingly limited by the code generator used. It is of limited power.

Those limitations can be worked around in some situations, by changing the way the script expects parameters, but an experienced tool developer
is probably the best choice at that point.

Reliable tests cannot be automatically generated for tools that create arbitrary collections, since the contents are not yet available at tool XML generation time.
They do appear after the test so send code - PR please if you care. A suitable test XML section can be supplied, as the Plotter example shows, but really, a Galaxy form
is a clumsy way to write XML. Better to use the proper developer tools, rather than a limited automated code generator, if you need collection outputs tested or other
hard to generate complications. Conventional development tools are recommended for wrapping complex packages.
The ToolFactory is only capable of meeting relatively simple needs, such as a handful of straightforward parameters and i/o files.

Long forms become unpleasant to navigate. In theory they should work, but clearly there will be many things that a simple XML
parser and document generator cannot do.

Sqlite works fine. Postgres seems faster but sqlite out of the box seems stable and useable.

If multiple Conda jobs run at the same time, processes can spin endlessly or dependencies may become corrupted, so job_conf.yml specifies a queue for the ToolFactory
that only runs jobs serially. All other tools run normally on the local runner.


## Local workstation installation for persistence - alternative to Docker non-persistent installation.

Clone this github repository in a convenient directory, and use *localtf.sh*  to bootstrap, configure and build a new development server, with
the following shell commands. It will install galaxy in a new and disposable directory, *galaxytf*.:

```
git clone https://github.com/fubar2/galaxy_tf_overlay.git
cd galaxy_tf_overlay
sh ./localtf.sh
```

Take a break for the 20+ minutes it will take to build and complete. A good time to read the rest of this documentation.
Running *localtf.sh* will create a new directory, *galaxytf*, in the parent directory of the *galaxy_tf_overlay* clone.
The script will download and configure a development server with the ToolFactory installed, into and below that new directory.
The steps include:

 * Download and unpack the current 23.0 release as at May 2023. Edit *localtf.sh* to suit your needs.
 * Install the ToolFactory configuration overlay from the local clone.
 * Build the client (very slow - visualisations are not built - edit *localtf.sh* to remove their removal) and setup Conda for dependencies (slow)
 * Create the default admin user and insert the API keys in various ToolFactory scripts.
 * Upload the default history and a workflow to build the examples.

This takes 20 minutes or more to complete - an extra ~10 for the visualisations.

A functioning development server will occupy ~9GB of disk space, so be sure your machine has plenty of room.
It will be based in a single directory, *galaxytf* in the same directory as the galaxy_tf_overlay repository was cloned into.
That is where the script should be run as shown above.

Rerunning the *localtf.sh* script will *destroy the entire galaxytf directory* - all ~9GB, and create a clean new installation.
It should only need to be run once in the life of the development server.

Remove the *galaxytf* directory to remove the entire development server when it is no longer needed. Save all your tools and histories,
because the jobs in a history can be used to update a tool easily, and a history can be imported into a fresh development instance
when needed.

Once local desktop installation is complete:
 * start the server from the *galaxytf* directory with *sh run.sh*. The logs will be displayed.
 * ^c (control+c) will stop it from the console.
 * In routine use, add the *--daemon* and *--stop-daemon* flags to run.sh, to start and stop the server in the background respectively.
 * In 23.0 that is equivalent to *.venv/bin/galaxyctl start* and *.venv/bin/galaxyctl stop*.


## Local installation and admin login
The default login is *toolfactory@galaxy.org* with password *ChangeMe!*
Please change it after logging in to the desktop version. Changes in the Docker version will be lost after shutting it down.

Only an administrator can execute the ToolFactory. Any new administrator email must be added to
*galaxytf/config/galaxy.yml* in the *admin_users* setting. Do not allow
any spaces between addresses, and restart the server for them to become active.
Do not remove the default admin *toolfactory@galaxy.org* or the ToolFactory will always fail because it depends on that API key in scripts.

### Do not expose this Galaxy server on the public internet. It is not secured.

All the usual layers of isolation required to make a server secure for public exposure, are missing as installed.
It's easy and safe to run locally, so installation on any public server is strongly discouraged.

The ToolFactory code *relies* on the default server's *lack of isolation*.
In any properly secured server, a running tool is unable to install, configure and test newly generated tools, but
that's exactly what the ToolFactory tool does. This is convenient and safe in a local disposable development server, but unsafe if exposed to hostile miscreants.
There is an important protection - *the ToolFactory will only work for administrative users*.
Ordinary and anonymous users can fill in the form, but it will be a waste of time, because tool execution exit with an error before a tool is generated.

Generated tools are ordinary Galaxy tools.
Code should always be inspected before installation from an untrusted source.
