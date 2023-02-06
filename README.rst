This is the overlay for a fresh Galaxy release_23.1 clone to turn it into a ToolFactory server.
The ToolFactory is a quick way for developers who can write scripts to create ordinary, shareable Galaxy tools, with having to learn how
to manually build Galaxy tool wrapper XML.

Planning and preparation are still needed, for a good tool.

To install, there is a supplied script to
 * do a shallow clone of the latest stable 22.05 release
 * add the ToolFactory configuration overlay
 * create the admin user
 * install the default history and a workflow to build all the examples, and
 * run a Planemo test.

This builds a new client and installs a lot of software, so takes 15-20 minutes to complete.
When it's done, use *sh run.sh --skip-client-build* to start the dev server and avoid a repeating slow build.
It should be ready in 30 seconds or less at *http://localhost:8080*.
Initial login as admin using *toolfactory@galaxy.org* with password *ChangeMe!* which of course you should change!

The easiest way to see how the ToolFactory works is to rerun and study the form settings for one of the examples in the default starting history
For example, if you have a Python script, there are argparse and positional parameter passing examples.
Take a look at argparse because it is far less prone to accidentally mixed up parameters.

Shell scripts examples include the tacrev and hello examples. Trivial, but they are working patterns for potentially more complicated and useful tools. Other
interpreters are used for trivial Lisp and Prolog scripting examples, and there is an R tool demonstrating how to produce output plots as collections.

Note that conventional development tools are recommended for wrapping complex packages. The ToolFactory is only useful for relatively simple needs
such as a handful of parameters and i/o files. Long forms become unpleasant to navigate although in theory they should work, but there are many
things that the ToolFactory cannot do. It is a very simple minded code generator, but is implemented as a Galaxy tool so you can run it in a
development Galaxy and test the new tools easily.

In addition to scripting interpreters, any Conda dependencies can be loaded for your script to use, as the BWA and Perl examples show.

It is best to start out with a working script of your own, that you know works properly on the command line for some small sample data inputs. Those
working sample data sets must be uploaded into a new history, ready to select on the ToolFactory form as input data for the test.

Details on each new tool component are needed for the form. These include:

 * the working script
 * conda dependencies and versions
 * input sample files ready in the history
 * output files
 * other user-controlled command line parameters.
 * how parameters are passed

 Most of these each need:

  * an internal parameter name
  * a parameter type
  * optional default value
  * user form prompt and help text

to prepare the ToolFactory form to build your new tool and test it with the supplied input data samples.

The new generated tool is installed in the local tools section, but may need a screen refresh to appear. It can be tested just as a user will see it from there.
The new tool is inside a Toolshed archive file in the history, together with a collection of tool related files. The archive is ready to upload to a toolshed if
it is sufficiently reliable and useful to share.

Collections can handle arbitrary script outputs to a single directory, as shown by the Plotter example. The repeats example shows how an
input parameter can be supplied to a tool on the command line as a user determined number of repeated parameter values.
The select example shows how to build a select parameter into a ToolFactory tool form and tests will include it.
These can be combined into tools without restriction, except that reliable tests cannot be automatically generated for tools that create
arbitrary collections since the contents are usually impossible to guess at tool generation time.
The plotter example shows how a suitable test XML section can be supplied if you know how to write it but then you might as well use the usual
proper toolkit rather than an automated generator.




.. figure:: https://galaxyproject.org/images/galaxy-logos/galaxy_project_logo.jpg
   :alt: Galaxy Logo

The latest information about Galaxy can be found on the `Galaxy Community Hub <https://galaxyproject.org/>`__.

Community support is available at `Galaxy Help <https://help.galaxyproject.org/>`__.

.. image:: https://img.shields.io/badge/chat-gitter-blue.svg
    :target: https://gitter.im/galaxyproject/Lobby
    :alt: Chat on gitter

.. image:: https://img.shields.io/badge/chat-irc.freenode.net%23galaxyproject-blue.svg
    :target: https://webchat.freenode.net/?channels=galaxyproject
    :alt: Chat on irc

.. image:: https://img.shields.io/badge/release-documentation-blue.svg
    :target: https://docs.galaxyproject.org/en/master/
    :alt: Release Documentation

.. image:: https://travis-ci.org/galaxyproject/galaxy.svg?branch=dev
    :target: https://travis-ci.org/galaxyproject/galaxy
    :alt: Inspect the test results


Issues and Galaxy Development
=============================

Please see `CONTRIBUTING.md <CONTRIBUTING.md>`_ .
