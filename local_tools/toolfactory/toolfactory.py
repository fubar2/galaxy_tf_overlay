# see https://github.com/fubar2/toolfactory
#
# copyright ross lazarus (ross stop lazarus at gmail stop com) May 2012
#
# all rights reserved
# Licensed under the LGPL
# suggestions for improvement and bug fixes welcome at
# https://github.com/fubar2/toolfactory
#
# February 2023: Refactored to use galaxy-tool-test script in galaxyutil
# planemo not needed if tool is already installed.
# sqlite does not seem to work - switch to postgresql in the installation script
#
# march 2022: Refactored into two tools - generate and test/install
# as part of GTN tutorial development and biocontainer adoption
# The tester runs planemo on a non-tested archive, creates the test outputs
# and returns a new proper tool with test.


import argparse
import copy
import json
import logging
import os
import re
import shlex
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time

from bioblend import galaxy
from bioblend import ConnectionError

import galaxyxml.tool as gxt
import galaxyxml.tool.parameters as gxtp

import lxml.etree as ET

import yaml


logger = logging.getLogger(__name__)


class Tool_Factory:
    """Wrapper for an arbitrary script
    uses galaxyxml
    """

    def __init__(self, args=None):  # noqa
        """
        prepare command line cl for running the tool here
        and prepare elements needed for galaxyxml tool generation
        """
        assert args.parampass in [
            "0",
            "embed",
            "argparse",
            "positional",
            "embednfmod",
        ], (
            "args.parampass %s not 0,positional, embed, embednfmod or argparse"
            % args.parampass
        )
        # sed will update these settings during tfsetup.py first run
        self.GALAXY_ADMIN_KEY = "956432473193251840"
        self.GALAXY_URL = "http://localhost:8080"
        self.profile = "22.05"
        self.not_iuc = True
        self.args = args
        self.tool_version = self.args.tool_version
        self.myversion = "V3.0 February 2023"
        self.verbose = True
        self.debug = True
        self.toolFactoryURL = "https://github.com/fubar2/galaxy_tf_overlay"
        self.logger = logging.getLogger(__name__)
        self.nfcoremod = False
        if args.parampass == "embednfmod":
            self.nfcoremod = True
        self.script_in_help = False  # IUC recommendation
        self.tool_name = re.sub("[^a-zA-Z0-9_]+", "", args.tool_name)
        self.tool_id = self.tool_name
        self.local_tools = os.path.realpath(
            os.path.join(args.galaxy_root, "local_tools")
        )
        self.repdir = os.path.realpath(args.tfcollection)
        self.testdir = os.path.join(self.repdir, self.tool_name)
        self.toold = os.path.join(self.local_tools, self.tool_name)
        self.tooltestd = os.path.join(self.toold, "test-data")
        if self.nfcoremod:
            self.local_tools = os.path.join(args.tfcollection, "tools")
            self.repdir = os.path.join(args.tfcollection, "TFouts", self.tool_name)
            self.toold = os.path.join(self.local_tools, self.tool_name)
            self.tooltestd = os.path.join(self.toold, "test-data")
        os.makedirs(self.repdir, exist_ok=True)
        os.makedirs(self.toold, exist_ok=True)
        os.makedirs(self.tooltestd, exist_ok=True)
        os.makedirs(self.local_tools, exist_ok=True)
        self.local_tool_conf = os.path.join(self.local_tools, "local_tool_conf.xml")
        self.ourcwd = os.getcwd()
        self.collections = []
        if len(args.collection) > 0:
            try:
                self.collections = [
                    json.loads(x) for x in args.collection if len(x.strip()) > 1
                ]
            except Exception:
                self.logger.error(
                    f"--collections parameter {str(args.collection)} is malformed - should be a dictionary"
                )
        self.infiles = []
        try:
            self.infiles = [
                json.loads(x) for x in args.input_files if len(x.strip()) > 1
            ]
        except Exception:
            self.logger.error(
                f"--input_files parameter {str(args.input_files)} is malformed - should be a dictionary"
            )
        self.extra_files = []
        if len(args.xtra_files) > 0:
            try:
                self.extra_files = [
                    json.loads(x) for x in args.xtra_files if len(x.strip()) > 1
                ]
            except Exception:
                self.logger.error(
                    f"--xtra_files parameter {str(args.xtra_files)} is malformed - should be a dictionary"
                )
        self.outfiles = []
        try:
            self.outfiles = [
                json.loads(x) for x in args.output_files if len(x.strip()) > 1
            ]
        except Exception:
            self.logger.error(
                f"--output_files parameter {args.output_files} is malformed - should be a dictionary"
            )
        assert (
            len(self.outfiles) + len(self.collections)
        ) > 0, "No outfiles or output collections specified. The Galaxy job runner will fail without an output of some sort"
        self.addpar = []
        try:
            self.addpar = [
                json.loads(x) for x in args.additional_parameters if len(x.strip()) > 1
            ]
        except Exception:
            self.logger.error(
                f"--additional_parameters {args.additional_parameters} is malformed - should be a dictionary"
            )
        self.selpar = []
        try:
            self.selpar = [
                json.loads(x) for x in args.selecttext_parameters if len(x.strip()) > 1
            ]
        except Exception:
            self.logger.error(
                f"--selecttext_parameters {args.selecttext_parameters} is malformed - should be a dictionary"
            )
        self.selfagpar = []
        try:
            self.selflagpar = [
                json.loads(x) for x in args.selectflag_parameters if len(x.strip()) > 1
            ]
        except Exception:
            self.logger.error(
                f"--selectflag_parameters {args.selecttext_parameters} is malformed - should be a dictionary"
            )
        self.cleanuppar()
        self.lastxclredirect = None
        self.xmlcl = []
        self.is_positional = self.args.parampass == "positional"
        self.is_embedded = self.args.parampass == "embedded"
        if self.args.sysexe:
            if " " in self.args.sysexe:
                self.executeme = shlex.split(self.args.sysexe)
            else:
                self.executeme = [
                    self.args.sysexe,
                ]
        else:
            if self.args.packages:
                self.executeme = [
                    self.args.packages.split(",")[0].split(":")[0].strip(),
                ]
            else:
                self.executeme = []
        aXCL = self.xmlcl.append
        self.newtarpath = args.tested_tool_out
        self.tinputs = gxtp.Inputs()
        self.toutputs = gxtp.Outputs()
        self.testparam = []
        if self.args.script_path:
            self.prepScript()
        else:
            self.script = None
        if self.args.cl_override != None:
            scos = open(self.args.cl_override, "r").readlines()
            self.cl_override = [x.rstrip() for x in scos]
        else:
            self.cl_override = None
        if self.args.test_override != None:
            stos = open(self.args.test_override, "r").readlines()
            self.test_override = [x.rstrip() for x in stos]
        else:
            self.test_override = None
        if self.args.cl_prefix != None:
            scos = open(self.args.cl_prefix, "r").readlines()
            self.cl_prefix = [x.rstrip() for x in scos]
        else:
            self.cl_prefix = None
        if self.args.cl_suffix != None:
            stos = open(self.args.cl_suffix, "r").readlines()
            self.cl_suffix = [x.rstrip() for x in stos]
        else:
            self.cl_suffix = None
        if self.args.script_path:
            for ex in self.executeme:
                if ex:
                    aXCL(ex)
            aXCL("'$runme'")
        else:
            for ex in self.executeme:
                aXCL(ex)
        if self.args.parampass == "0":
            self.clsimple()
        elif self.args.parampass == "positional":
            self.prepclpos()
            self.clpositional()
        elif self.args.parampass == "argparse":
            self.prepargp()
            self.clargparse()
        elif self.args.parampass.startswith("embed"):
            self.prepembed()
        else:
            logging.error(
                "Parampass value %s not in 0, positional, argparse, embed or embednfmod"
                % self.args.parampass
            )
            logging.shutdown()
            sys.exit(6)

    def clsimple(self):
        """no parameters or repeats - uses < and > for i/o"""
        aXCL = self.xmlcl.append
        if len(self.infiles) > 0:
            aXCL("<")
            aXCL("'$%s'" % self.infiles[0]["infilename"])
        if len(self.outfiles) > 0:
            aXCL(">")
            aXCL("'$%s'" % self.outfiles[0]["name"])

    def prepembed(self):
        """fix self.script"""
        scrip = self.script
        if self.nfcoremod:
            self.script = (
                '#set prefix = "%s"\n#set task_process = "%s"\n'
                % (self.tool_name, self.tool_name)
                + scrip
            )
        self.xmlcl = []  # wipe anything there
        aX = self.xmlcl.append
        aX("")
        if self.nfcoremod:
            aX('#set prefix = "%s"' % self.tool_name)
            aX('#set task_process = "%s"' % self.tool_name)
        for p in self.collections:
            aX("mkdir -p %s &&" % p["name"])
        aX("%s '$runme'" % self.args.sysexe)

    def prepargp(self):
        xclsuffix = []
        for i, p in enumerate(self.infiles):
            rep = p["required"] in ["optional1", "required1"]
            req = p["required"] in ["required", "required1"]
            nam = p["infilename"]
            flag = p["CL"]
            if p["origCL"].strip().upper() == "STDIN":
                xappendme = [
                    nam,
                    nam,
                    "< '$%s'" % nam,
                ]
            else:
                xappendme = [p["CL"], "'$%s'" % p["CL"], ""]
            xclsuffix.append(xappendme)
        for i, p in enumerate(self.outfiles):
            if p["origCL"].strip().upper() == "STDOUT":
                self.lastxclredirect = [">", "'$%s'" % p["name"]]
            else:
                xclsuffix.append([p["name"], "'$%s'" % p["name"], ""])
        for p in self.addpar:
            nam = p["name"]
            val = p["value"]
            flag = p["CL"]
            rep = p.get("repeat", 0) == "1"
            if rep:
                over = f'#for $rep in $R_{nam}:\n--{nam} "$rep.{nam}"\n#end for'
            else:
                over = p.get("override", "")
            if p["type"] == "clflag":
                over = f'#if ${nam} == "set"\n --{flag}\n#end if'
            xclsuffix.append([p["CL"], "'$%s'" % nam, over])
        for p in self.selpar:
            xclsuffix.append([p["CL"], "'$%s'" % p["name"], p.get("override", "")])
        for p in self.selflagpar:
            xclsuffix.append(["", "'$%s'" % p["name"], ""])
        for p in self.collections:
            newname = p["name"]
            xclsuffix.append([newname, "'%s'" % newname, ""])
        self.xclsuffix = xclsuffix

    def prepclpos(self):
        xclsuffix = []
        for i, p in enumerate(self.infiles):
            if p["origCL"].strip().upper() == "STDIN":
                xappendme = [
                    "999",
                    p["infilename"],
                    "< '$%s'" % p["infilename"],
                ]
            else:
                xappendme = [p["CL"], "'$%s'" % p["infilename"], ""]
            xclsuffix.append(xappendme)
        for i, p in enumerate(self.outfiles):
            if p["origCL"].strip().upper() == "STDOUT":
                self.lastxclredirect = [">", "'$%s'" % p["name"]]
            else:
                xclsuffix.append([p["CL"], "'$%s'" % p["name"], ""])
        for p in self.addpar:
            nam = p["name"]
            rep = p.get("repeat", "0") == "1"  # repeats make NO sense
            if rep:
                logger.warning(
                    f"### warning. Repeats for {nam} ignored - not permitted in positional parameter command lines!"
                )
            over = p.get("override", "")
            xclsuffix.append([p["CL"], "'$%s'" % nam, over])
        for p in self.selpar:
            xclsuffix.append([p["CL"], "'$%s'" % p["name"], p.get("override", "")])
        for p in self.selflagpar:
            xclsuffix.append(["", "'$%s'" % p["name"], ""])
        for p in self.collections:
            newname = p["name"]
            xclsuffix.append([newname, "'$%s'" % newname, ""])
        xclsuffix.sort()
        self.xclsuffix = xclsuffix

    def prepScript(self):
        s = open(self.args.script_path, "r").read()
        ss = s.split("\n")
        rxcheck = [x for x in ss if x.strip() > ""]
        assert len(rxcheck) > 0, "Supplied script is empty. Cannot run"
        if self.args.sysexe and self.args.parampass != "embed":
            rxcheck.insert(0, "#raw")
            rxcheck.append("#end raw")
        self.script = "\n".join(rxcheck)
        if len(self.executeme) > 0:
            self.sfile = os.path.join(
                self.repdir, "%s.%s.txt" % (self.tool_name, self.executeme[0])
            )
        else:
            self.sfile = os.path.join(
                self.repdir, "%s.script.txt" % (self.tool_name)
            )
        tscript = open(self.sfile, "w")
        tscript.write(self.script)
        tscript.write("\n")
        tscript.close()
        self.spacedScript = [
            f"    {x.replace('${','$ {')}" for x in ss if x.strip() > ""
        ]
        self.escapedScript = rxcheck

    def cleanuppar(self):
        """positional parameters are complicated by their numeric ordinal"""
        if self.args.parampass == "positional":
            for i, p in enumerate(self.infiles):
                assert (
                    p["CL"].isdigit() or p["CL"].strip().upper() == "STDIN"
                ), "Positional parameters must be ordinal integers - got %s for %s" % (
                    p["CL"],
                    p["label"],
                )
            for i, p in enumerate(self.outfiles):
                assert (
                    p["CL"].isdigit() or p["CL"].strip().upper() == "STDOUT"
                ), "Positional parameters must be ordinal integers - got %s for %s" % (
                    p["CL"],
                    p["name"],
                )
            for i, p in enumerate(self.addpar):
                assert p[
                    "CL"
                ].isdigit(), "Positional parameters must be ordinal integers - got %s for %s" % (
                    p["CL"],
                    p["name"],
                )
        for i, p in enumerate(self.infiles):
            infp = copy.copy(p)
            infp["origCL"] = infp["CL"]
            if self.args.parampass in ["positional", "0"]:
                infp["infilename"] = infp["label"].replace(" ", "_")
            else:
                infp["infilename"] = infp["CL"]
            self.infiles[i] = infp
        for i, p in enumerate(self.outfiles):
            outfp = copy.copy(p)
            outfp["origCL"] = outfp["CL"]  # keep copy
            if outfp.get("label", None) == None:
                outfp["label"] = ""
            self.outfiles[i] = outfp
        for i, p in enumerate(self.addpar):
            addp = copy.copy(p)
            addp["origCL"] = addp["CL"]
            self.addpar[i] = addp
        for i, p in enumerate(self.collections):
            addp = copy.copy(p)
            addp["CL"] = addp["name"]
            self.collections[i] = addp

    def clpositional(self):
        # inputs in order then params
        aXCL = self.xmlcl.append
        for (k, v, koverride) in self.xclsuffix:
            aXCL(v)
        if self.lastxclredirect:
            for cl in self.lastxclredirect:
                aXCL(cl)

    def clargparse(self):
        """argparse style"""
        aXCL = self.xmlcl.append
        # inputs then params in argparse named form
        for (k, v, koverride) in self.xclsuffix:
            if koverride > "":
                k = koverride
                aXCL(k)
            else:
                kl = len(k.strip())
                if kl == 0:
                    k = " "
                elif kl == 1:
                    k = "-%s" % k
                else:
                    k = "--%s" % k
                aXCL(k)
                aXCL(v)
        if self.lastxclredirect:
            for cl in self.lastxclredirect:
                aXCL(cl)

    def getNdash(self, newname):
        if self.is_positional:
            ndash = 0
        else:
            ndash = 2
            if len(newname) < 2:
                ndash = 1
        return ndash

    def doXMLparam(self):  # noqa
        """Add all needed elements to tool"""
        for p in self.outfiles:
            newname = p["name"]
            newfmt = p["format"]
            newcl = p["CL"]
            test = p["test"]
            oldcl = p["origCL"]
            test = test.strip()
            filta = p.get("when", [])
            lab = p.get("label", "")
            if len(lab.strip()) == 0:
                lab = newname
            ndash = self.getNdash(newcl)
            aparm = gxtp.OutputData(
                name=newname, format=newfmt, num_dashes=ndash, label=lab
            )
            if len(filta) > 0:
                ofilta = gxtp.ChangeFormat()
                for (
                    whens
                ) in filta:  # when input=|image_type| value=|large_png| format=|png|
                    whenss = whens.replace("|", '"').replace("when ", "")
                    clauses = whenss.split()
                    for c in clauses:
                        if c.startswith("value"):
                            v = c.split("=")[1]
                        elif c.startswith("format"):
                            f = c.split("=")[1]
                        elif c.startswith("input"):
                            i = c.split("=")[1]
                        else:
                            print(
                                "bad when - need value=, format= and input=, got", whens
                            )
                    owhen = gxtp.ChangeFormatWhen(format=f, input=i, value=v)
                    ofilta.append(owhen)
                aparm.append(ofilta)
            aparm.positional = self.is_positional
            if self.is_positional:
                if oldcl.upper() == "STDOUT":
                    aparm.positional = 9999999
                    aparm.command_line_override = "> '$%s'" % newname
                else:
                    aparm.positional = int(oldcl)
                    aparm.command_line_override = "'$%s'" % newname
            self.toutputs.append(aparm)
            ld = None
            if test.strip() > "":
                if test.strip().startswith("diff"):
                    c = "diff"
                    ld = 0
                    if test.split(":")[1].isdigit:
                        ld = int(test.split(":")[1])
                    tp = gxtp.TestOutput(
                        name=newname,
                        value="%s_sample" % newname,
                        compare=c,
                        lines_diff=ld,
                    )
                elif test.startswith("sim_size"):
                    c = "sim_size"
                    tn = test.split(":")[1].strip()
                    if tn > "":
                        if "." in tn:
                            delta = None
                            delta_frac = min(1.0, float(tn))
                        else:
                            delta = int(tn)
                            delta_frac = None
                    tp = gxtp.TestOutput(
                        name=newname,
                        value="%s_sample" % newname,
                        compare=c,
                        delta=delta,
                        delta_frac=delta_frac,
                    )
                else:
                    c = test
                    tp = gxtp.TestOutput(
                        name=newname,
                        value="%s_sample" % newname,
                        compare=c,
                    )
                self.testparam.append(tp)
        for p in self.infiles:
            newname = p["infilename"]
            newfmt = p["format"]
            ndash = self.getNdash(newname)
            reps = p.get("required", "") in ["optional1", "required1"]
            isoptional = p.get("required", "") in ["optional", "optional1"]
            if not len(p["label"]) > 0:
                alab = p["CL"]
            else:
                alab = p["label"]
            aninput = gxtp.DataParam(
                newname,
                optional=isoptional,
                label=alab,
                help=p["help"],
                format=newfmt,
                multiple=reps,
                num_dashes=ndash,
            )
            aninput.positional = self.is_positional
            if self.is_positional:
                if p["origCL"].upper() == "STDIN":
                    aninput.positional = 9999998
                    aninput.command_line_override = "< '$%s'" % newname
                else:
                    aninput.positional = int(p["origCL"])
                    aninput.command_line_override = "'$%s'" % newname
            self.tinputs.append(aninput)
            tparm = gxtp.TestParam(newname, value="%s_sample" % newname)
            self.testparam.append(tparm)
        for p in self.addpar:
            newname = p["name"]
            newval = p.get("value", "")
            newlabel = p["label"]
            newhelp = p.get("help", "")
            newtype = p.get("type", "?")
            newcl = p["CL"]
            oldcl = p["origCL"]
            reps = p.get("repeat", "0") == "1"
            if not len(newlabel) > 0:
                newlabel = newname
            ndash = self.getNdash(newname)
            if newtype == "text":
                aparm = gxtp.TextParam(
                    newname,
                    label=newlabel,
                    help=newhelp,
                    value=newval,
                    num_dashes=ndash,
                )
            elif newtype == "integer":
                aparm = gxtp.IntegerParam(
                    newname,
                    label=newlabel,
                    help=newhelp,
                    value=int(newval.replace("'", "").replace('"', "")),
                    num_dashes=ndash,
                )
            elif newtype == "float":
                aparm = gxtp.FloatParam(
                    newname,
                    label=newlabel,
                    help=newhelp,
                    value=float(newval.replace("'", "").replace('"', "")),
                    num_dashes=ndash,
                )
            elif newtype == "boolean":
                aparm = gxtp.BooleanParam(
                    newname,
                    label=newlabel,
                    help=newhelp,
                    value=newval,
                    num_dashes=ndash,
                )
            elif newtype == "clflag":
                initval = newval
                aparm = gxtp.SelectParam(
                    newname,
                    label=newlabel,
                    help=newhelp,
                    num_dashes=ndash,
                    display="radio",
                )
                anoptt = gxtp.SelectOption(
                    value="set",
                    text="Set this flag",
                )
                anoptf = gxtp.SelectOption(
                    value="notset",
                    text="Do not set this flag",
                )
                if p["value"] == "set":  # make default same as form
                    aparm.append(anoptt)
                    aparm.append(anoptf)
                else:
                    aparm.append(anoptf)
                    aparm.append(anoptt)
            elif newtype == "datacolumn":
                aparm = gxtp.TextParam(
                    newname,
                    type="data_column",
                    data_ref=p["dataref"],
                    multiple=(p["multiple"] == "1"),
                    label=newlabel,
                    help=newhelp,
                    value=newval,
                    num_dashes=ndash,
                )
            else:
                raise ValueError(
                    'Unrecognised parameter type "%s" for \
                 additional parameter %s in makeXML'
                    % (newtype, newname)
                )
            aparm.positional = self.is_positional
            if self.is_positional:
                aparm.positional = int(oldcl)
            if reps:
                repe = gxtp.Repeat(
                    name=f"R_{newname}",
                    title=f"Any number of {newlabel} repeats are allowed",
                )
                repe.append(aparm)
                self.tinputs.append(repe)
                tparm = gxtp.TestRepeat(name=f"R_{newname}")
                tparm2 = gxtp.TestParam(newname, value=newval)
                tparm.append(tparm2)
                self.testparam.append(tparm)
            else:
                self.tinputs.append(aparm)
                tparm = gxtp.TestParam(newname, value=newval)
                self.testparam.append(tparm)
        for p in self.selpar:
            newname = p["name"]
            newval = p.get("value", "")
            newlabel = p["label"]
            newhelp = p["help"]
            newtype = p["type"]
            newcl = p["CL"]
            if not len(newlabel) > 0:
                newlabel = newname
            ndash = self.getNdash(newname)
            if newtype == "selecttext":
                newtext = p["texts"]
                aparm = gxtp.SelectParam(
                    newname,
                    label=newlabel,
                    help=newhelp,
                    num_dashes=ndash,
                )
                for i in range(len(newval)):
                    anopt = gxtp.SelectOption(
                        value=newval[i],
                        text=newtext[i],
                    )
                    aparm.append(anopt)
                aparm.positional = self.is_positional
                if self.is_positional:
                    aparm.positional = int(newcl)
                self.tinputs.append(aparm)
                tparm = gxtp.TestParam(newname, value=newval[0])
                self.testparam.append(tparm)
            else:
                raise ValueError(
                    'Unrecognised parameter type "%s" for\
                 selecttext parameter %s in makeXML'
                    % (newtype, newname)
                )
        for p in self.selflagpar:
            newname = p["name"]
            newval = p["value"]
            newlabel = p["label"]
            newhelp = p["help"]
            newtype = p["type"]
            newtext = p["texts"]
            newcl = p["CL"]
            if not len(newlabel) > 0:
                newlabel = newname
            aparm = gxtp.SelectParam(
                newname,
                label=newlabel,
                help=newhelp,
                num_dashes=0,
            )
            for i in range(len(newval)):
                anopt = gxtp.SelectOption(
                    value=newval[i],
                    text=newtext[i],
                )
                aparm.append(anopt)
            aparm.positional = self.is_positional
            if self.is_positional:
                aparm.positional = int(newcl)
            self.tinputs.append(aparm)
            tparm = gxtp.TestParam(newname, value=newval[0])
            self.testparam.append(tparm)

    def doNoXMLparam(self):
        """filter style package - stdin to stdout"""
        if len(self.infiles) > 0:
            alab = self.infiles[0]["label"]
            if len(alab) == 0:
                alab = self.infiles[0]["infilename"]
            max1s = (
                "Maximum one input if parampass is 0 but multiple input files supplied - %s"
                % str(self.infiles)
            )
            assert len(self.infiles) == 1, max1s
            newname = self.infiles[0]["infilename"]
            aninput = gxtp.DataParam(
                newname,
                optional=False,
                label=alab,
                help=self.infiles[0]["help"],
                format=self.infiles[0]["format"],
                multiple=False,
                num_dashes=0,
            )
            aninput.command_line_override = "< $%s" % newname
            aninput.positional = True
            self.tinputs.append(aninput)
            tp = gxtp.TestParam(name=newname, value="%s_sample" % newname)
            self.testparam.append(tp)
        if len(self.outfiles) > 0:
            newname = self.outfiles[0]["name"]
            newfmt = self.outfiles[0]["format"]
            anout = gxtp.OutputData(newname, format=newfmt, num_dashes=0)
            anout.command_line_override = "> $%s" % newname
            anout.positional = self.is_positional
            self.toutputs.append(anout)
            tp = gxtp.TestOutput(name=newname, value="%s_sample" % newname)
            self.testparam.append(tp)

    def makeXML(self):  # noqa
        """
        Create a Galaxy xml tool wrapper for the new script
        Uses galaxyhtml
        Hmmm. How to get the command line into correct order...
        """
        requirements = gxtp.Requirements()
        self.condaenv = []
        if self.args.packages:
            try:
                for d in self.args.packages.split(","):
                    ver = None
                    packg = None
                    d = d.replace("==", ":")
                    d = d.replace("=", ":")
                    if ":" in d:
                        packg, ver = d.split(":")[:2]
                        ver = ver.strip()
                        packg = packg.strip()
                        self.tool_version = ver
                    else:
                        packg = d.strip()
                        ver = None
                    if ver == "":
                        ver = None
                    if packg:
                        requirements.append(
                            gxtp.Requirement("package", packg.strip(), ver)
                        )
                        self.condaenv.append(d)
            except Exception:
                self.logger.error(
                    "### malformed packages string supplied - cannot parse = %s"
                    % self.args.packages
                )
                sys.exit(2)
        elif self.args.container:
            requirements.append(gxtp.Requirement("container", self.args.container))
        self.newtool = gxt.Tool(
            self.tool_name,
            self.tool_id,
            self.tool_version,
            self.args.tool_desc,
            "",
            profile=self.profile,
        )
        self.newtool.requirements = requirements
        iXCL = self.xmlcl.insert
        aXCL = self.xmlcl.append
        if self.args.cl_prefix:  # DIY CL start
            self.xmlcl = self.cl_prefix + self.xmlcl
        if self.args.cl_suffix:  # DIY CL end
            self.xmlcl += self.cl_suffix
        if self.cl_override:
            self.newtool.command_override = self.cl_override  # config file
        else:
            self.newtool.command_override = self.xmlcl
        self.cites = self.parse_citations()
        cite = gxtp.Citations()
        if self.cites and len(self.cites) > 0:
            for c in self.cites:
                acite = gxtp.Citation(type=c[0], value=c[1])
                cite.append(acite)
        acite = gxtp.Citation(type="doi", value="10.1093/bioinformatics/bts573")
        cite.append(acite)
        self.newtool.citations = cite
        safertext = ""
        if self.args.help_text:
            self.helptext = open(self.args.help_text, "r").readlines()
            safertext = "\n".join([self.cheetah_escape(x) for x in self.helptext])
        if len(safertext.strip()) == 0:
            safertext = (
                "Ask the tool author (%s) to rebuild with help text please\n"
                % (self.args.user_email)
            )
        if self.script_in_help and self.args.script_path:
            if len(safertext) > 0:
                safertext = safertext + "\n\n------\n"  # transition allowed!
            scr = [x for x in self.spacedScript if x.strip() > ""]
            scr.insert(0, "\n\nScript::\n")
            if len(scr) > 300:
                scr = (
                    scr[:100]
                    + ["    >300 lines - stuff deleted", "    ......"]
                    + scr[-100:]
                )
            scr.append("\n")
            safertext = safertext + "\n".join(scr)
        self.newtool.help = " ".join(self.helptext)
        for p in self.collections:
            newkind = p["kind"]
            newname = p["name"]
            newlabel = p["label"]
            newdisc = p["discover"]
            collect = gxtp.OutputCollection(newname, label=newlabel, type=newkind)
            disc = gxtp.DiscoverDatasets(
                pattern=newdisc, directory=f"{newname}", visible="false"
            )
            collect.append(disc)
            self.toutputs.append(collect)
            try:
                tparm = gxtp.TestOutputCollection(newname)  # broken until PR merged.
                self.testparam.append(tparm)
            except Exception:
                logging.error(
                    "WARNING: Galaxyxml version does not have the PR merged yet - tests for collections must be over-ridden until then!"
                )
        self.newtool.version_command = f'echo "{self.tool_version}"'
        if self.args.parampass == "0":
            self.doNoXMLparam()
        else:
            self.doXMLparam()
        self.newtool.outputs = self.toutputs
        self.newtool.inputs = self.tinputs
        if self.args.script_path:
            configfiles = gxtp.Configfiles()
            configfiles.append(gxtp.Configfile(name="runme", text=self.script))
            self.newtool.configfiles = configfiles
        tests = gxtp.Tests()
        test_a = gxtp.Test()
        for tp in self.testparam:
            test_a.append(tp)
        tests.append(test_a)
        self.newtool.tests = tests
        self.newtool.add_comment(
            "Created by %s at %s using the Galaxy Tool Factory."
            % (self.args.user_email, self.timenow())
        )
        self.newtool.add_comment("Source in git at: %s" % (self.toolFactoryURL))
        exml = self.newtool.export()
        if (
            self.test_override
        ):  # cannot do this inside galaxyxml as it expects lxml objects for tests
            part1 = exml.split("<tests>")[0]
            part2 = exml.split("</tests>")[1]
            fixed = "%s\n%s\n%s" % (part1, "\n".join(self.test_override), part2)
            exml = fixed
        with open(os.path.join(self.toold, "%s.xml" % self.tool_name), "w") as xf:
            xf.write(exml)
            xf.write("\n")
        with open(os.path.join(self.repdir, "%s_xml.xml" % self.tool_name), "w") as xf:
            xf.write(exml)
            xf.write("\n")

    def writeShedyml(self):
        """for planemo"""
        yuser = self.args.user_email.split("@")[0]
        yfname = os.path.join(self.toold, ".shed.yml")
        yamlf = open(yfname, "w")
        odict = {
            "name": self.tool_name,
            "owner": "fubar2",
            "type": "unrestricted",
            "description": "ToolFactory autogenerated tool",
            "synopsis": self.args.tool_desc,
            "category": "ToolFactory generated Tools",
        }
        yaml.dump(odict, yamlf, allow_unicode=True)
        yamlf.close()

    def writeTFyml(self):
        """for posterity"""
        adict = {}
        rargs = [
            "input_files",
            "output_files",
            "additional_parameters",
            "selecttext_parameters",
            "selectflag_parameters",
            "xtra_files",
        ]
        args = vars(self.args)
        for k in args.keys():
            if k not in rargs:
                adict[k] = args.get(k, None)
            else:
                if adict.get(k, None):
                    adict[k].append(adict[k])
                else:
                    adict[k] = [args.get(k, None)]
        adict["script"] = self.script
        adict["help"] = self.helptext
        yfname = os.path.join(self.repdir, "%s_ToolFactory.yml" % self.tool_name)
        yf = open(yfname, "w")
        yaml.dump(adict, yf)
        yf.close()

    def saveTestdata(self, pname, testDataURL):
        """
        may need to be ungzipped and in test folder
        """
        res = 0
        localpath = os.path.join(self.tooltestd, "%s_sample" % pname)
        print("#### save", testDataURL, "for", pname, "to", localpath)
        if not os.path.exists(localpath):
            cl = [
                "wget",
                "--timeout",
                "5",
                "--tries",
                "2",
                "-O",
                localpath,
                testDataURL,
            ]
            if testDataURL.endswith(".gz"):  # major kludge as usual...
                gzlocalpath = "%s.gz" % localpath
                cl = [
                    "wget",
                    "-q",
                    "--timeout",
                    "5",
                    "--tries",
                    "2",
                    "-O",
                    gzlocalpath,
                    testDataURL,
                    "&&",
                    "rm",
                    "-f",
                    localpath,
                    "&&",
                    "gunzip",
                    gzlocalpath,
                ]
            p = subprocess.run(" ".join(cl), shell=True)
            if p.returncode:
                print("Got", p.returncode, "from executing", " ".join(cl))
        else:
            print("Not re-downloading", localpath)
        return res

    def makeTool(self):
        """write xmls and input samples into place"""
        if self.args.parampass == 0:
            self.doNoXMLparam()
        else:
            self.makeXML()
        if self.args.script_path and self.not_iuc:
            stname = os.path.join(self.toold, os.path.split(self.sfile)[1])
            if not os.path.exists(stname):
                shutil.copyfile(self.sfile, stname)
                logger.info("Copied %s to %s" % (self.sfile, stname))
        for p in self.infiles:
            paths = p["name"]
            pname = p["CL"]
            pathss = paths.split(",")
            np = len(pathss)
            if p.get("URL", None):
                res = self.saveTestdata(pname, p["URL"])
            for i, pth in enumerate(pathss):
                if os.path.exists(pth):
                    if np > 1:
                        dest = os.path.join(
                            self.tooltestd, "%s_%d_sample" % (p["infilename"], i + 1)
                        )
                    else:
                        dest = os.path.join(
                            self.tooltestd, "%s_sample" % p["infilename"]
                        )
                    shutil.copyfile(pth, dest)
                    logger.info("Copied %s to %s" % (pth, dest))
                else:
                    logger.info(
                        "Optional input path %s does not exist - not copied" % pth
                    )
        if self.extra_files and len(self.extra_files) > 0:
            for xtra in self.extra_files:
                fpath = xtra["fpath"]
                dest = os.path.join(self.toold, xtra["fname"])
                shutil.copyfile(fpath, dest)
                logger.info("Copied xtra file %s to %s" % (fpath, dest))
        shutil.copytree(self.toold, self.testdir, dirs_exist_ok=True)

    def makeToolTar(self, test_retcode=0):
        """move outputs into test-data and prepare the tarball"""
        excludeme = "tool_test_output"

        def exclude_function(tarinfo):
            filename = tarinfo.name
            return None if filename.startswith(excludeme) else tarinfo

        logger.info("makeToolTar starting with tool test retcode=%d\n" % test_retcode)
        td = os.listdir(self.toold)
        for f in td:
            if f.startswith("tool_test_output"):
                os.unlink(os.path.join(self.toold, f))
        if self.newtarpath:
            tf = tarfile.open(self.newtarpath, "w:gz")
            tf.add(
                name=self.toold,
                arcname=self.tool_name,
                # filter=exclude_function,
            )

    def planemo_local_test(self):
        """
        weird legacyversion error popping up again from package version upgrade in conda_util.py in the venv.
        Seems ok if run as a shell script using the Galaxy installed planemo august 1st 2023
        """
        shutil.copytree(self.toold, self.testdir, dirs_exist_ok=True)
        x = "%s.xml" % self.tool_name
        xout = os.path.abspath(os.path.join(self.testdir, x))
        cl = [
            "planemo",
            "test",
            "--galaxy_admin_key",
            self.GALAXY_ADMIN_KEY,
            "--engine",
            "external_galaxy",
            "--update_test_data",
            "--galaxy_url",
            self.GALAXY_URL,
            xout,
        ]
        clx = [
            "planemo",
            "test",
            "--galaxy_admin_key",
            "[GALAXY_ADMIN_KEY]",
            "--engine",
            "external_galaxy",
            "--update_test_data",
            "--galaxy_url",
            self.GALAXY_URL,
            xout,
        ]
        logger.info("planemo_local_test executing: %s" % " ".join(clx))
        p = subprocess.run(
            " ".join(cl),
            timeout=600,
            shell=True,
            cwd=self.testdir,
            capture_output=True,
            check=True,
            text=True,
        )
        for errline in p.stderr.splitlines():
            logger.info("planemo: %s" % errline)
        for errline in p.stdout.splitlines():
            logger.info("planemo: %s" % errline)
        shutil.copytree(self.testdir, self.toold, dirs_exist_ok=True)
        dest = self.repdir
        src = self.tooltestd
        logger.info("copying to %s to %s test_outs" % (src, dest))
        shutil.copytree(src, dest, dirs_exist_ok=True)
        return p.returncode

    def fast_local_test(self):
        """
        galaxy-tool-test -u http://localhost:8080 -a 1613612977827175424 -t tacrev -o local --publish-history
        Seems to have a race condition when multiple jobs running. Works well - 15 secs or so if only onejob at a time! so job_conf fixed.
        Failure will eventually get stuck. Might need a timeout in the script
        """
        scrpt = os.path.join(self.args.toolfactory_dir, "toolfactory_fast_test.sh")
        extrapaths = self.tooltestd
        cl = ["/usr/bin/bash", scrpt, self.tool_name, extrapaths, extrapaths]
        logger.info("fast_local_test executing %s \n" % (" ".join(cl)))
        p = subprocess.run(
            " ".join(cl),
            shell=True,
            cwd=self.testdir,
            capture_output=True,
            check=True,
            text=True,
        )
        for errline in p.stderr.splitlines():
            logger.info("ephemeris: %s" % errline)
        for errline in p.stdout.splitlines():
            logger.info("ephemeris: %s" % errline)
        shutil.copytree(self.testdir, self.toold, dirs_exist_ok=True)
        dest = self.repdir
        src = self.tooltestd
        shutil.copytree(src, dest, dirs_exist_ok=True)
        return p.returncode

    def update_toolconf(self, remove=False):
        """tempting to recreate it from the local_tools directory each time
        currently adds new tools if not there.
        """

        def sortchildrenby(parent, attr):
            parent[:] = sorted(parent, key=lambda child: child.get(attr))

        logger.info("Updating tool conf files for %s\n" % (self.tool_name))
        tcpath = self.local_tool_conf
        xmlfile = os.path.join(self.tool_name, "%s.xml" % self.tool_name)
        try:
            parser = ET.XMLParser(remove_blank_text=True)
            tree = ET.parse(tcpath, parser)
        except ET.XMLSyntaxError:
            logger.error(
                "### Tool configuration update access error - %s cannot be parsed as xml by element tree\n"
                % tcpath
            )
            sys.exit(4)
        root = tree.getroot()
        hasTF = False
        e = root.findall("section")
        if len(e) > 0:
            hasTF = True
            TFsection = e[0]
        if not hasTF:
            TFsection = ET.Element(
                "section", {"id": "localtools", "name": "Local Tools"}
            )
            root.insert(0, TFsection)  # at the top!
        our_tools = TFsection.findall("tool")
        conf_tools = [x.attrib["file"] for x in our_tools]
        if not remove:
            if xmlfile not in conf_tools:  # new
                ET.SubElement(TFsection, "tool", {"file": xmlfile})
            sortchildrenby(TFsection, "file")
            tree.write(tcpath, pretty_print=True)
            gi = galaxy.GalaxyInstance(url=self.GALAXY_URL, key=self.GALAXY_ADMIN_KEY)
            toolready = False
            now = time.time()
            nloop = 5
            while nloop >= 0 and not toolready:
                try:
                    res = gi.tools.show_tool(tool_id=self.tool_name)
                    toolready = True
                    logger.info(
                        "Tool %s ready after %f seconds - %s\n"
                        % (self.tool_name, time.time() - now, res)
                    )
                except ConnectionError:
                    nloop -= 1
                    time.sleep(2)
                    logger.info("Connection error - waiting 2 seconds.\n")
            if nloop < 1:
                logger.error(
                    "Tool %s still not ready after %f seconds - please check the form and the generated xml for errors? \n"
                    % (self.tool_name, time.time() - now)
                )
                return 2
            else:
                return 0
        else:
            if xmlfile in conf_tools:  # remove
                for rem in our_tools:
                    if rem.attrib["file"] == xmlfile:
                        rem.getparent().remove(rem)
                        self.logger.info(
                            "###=============== removed tool %s from %s"
                            % (xmlfile, tcpath)
                        )
                sortchildrenby(TFsection, "file")
                tree.write(tcpath, pretty_print=True)

    def install_deps(self):
        """
        use script to install new tool dependencies
        """
        cll = [
            "sh",
            "%s/install_tf_deps.sh" % self.args.toolfactory_dir,
            self.tool_name,
        ]
        self.logger.info("Running %s\n" % " ".join(cll))
        try:
            p = subprocess.run(
                " ".join(cll), shell=True, capture_output=True, check=True, text=True
            )
            for errline in p.stderr.splitlines():
                self.logger.info(errline)
            return p.returncode
        except:
            return 1

    def timenow(self):
        """return current time as a string"""
        return time.strftime("%d/%m/%Y %H:%M:%S", time.localtime(time.time()))

    def cheetah_escape(self, text):
        """Produce entities within text."""
        cheetah_escape_table = {"$": "\\$", "#": "\\#"}
        return "".join([cheetah_escape_table.get(c, c) for c in text])

    def parse_citations(self):
        """"""
        if self.args.citations:
            ct = open(self.args.citations, "r").read()
            citations = [c.strip() for c in ct.split("**ENTRY**") if c.strip()]
            citation_tuples = []
            for citation in citations:
                if citation.startswith("doi"):
                    citation_tuples.append(("doi", citation[len("doi") :].strip()))
                else:
                    citation_tuples.append(
                        ("bibtex", citation[len("bibtex") :].strip())
                    )
            return citation_tuples
        else:
            return None


def main():
    """
    This is a Galaxy wrapper.
    It expects to be called by a special purpose tool.xml

    """
    parser = argparse.ArgumentParser()
    a = parser.add_argument
    a("--nftest", action="store_true", default=False)
    a("--script_path", default=None)
    a("--sysexe", default=None)
    a("--packages", default=None)
    a("--tool_name", default="newtool")
    a("--input_files", default=[], action="append")
    a("--output_files", default=[], action="append")
    a("--user_email", default="Unknown")
    a("--bad_user", default=None)
    a("--help_text", default=None)
    a("--tool_desc", default=None)
    a("--toolfactory_dir", default=None)
    a("--tool_version", default="0.01")
    a("--citations", default=None)
    a("--cl_suffix", default=None)
    a("--cl_prefix", default=None)
    a("--cl_override", default=None)
    a("--test_override", default=None)
    a("--additional_parameters", action="append", default=[])
    a("--selecttext_parameters", action="append", default=[])
    a("--selectflag_parameters", action="append", default=[])
    a("--edit_additional_parameters", action="store_true", default=False)
    a("--parampass", default="positional")
    a("--tfcollection", default="toolgen")
    a("--galaxy_root", default="/galaxy-central")
    a("--collection", action="append", default=[])
    a("--include_tests", default=False, action="store_true")
    a("--install_flag", action="store_true", default=False)
    a("--admin_only", default=True, action="store_true")
    a("--tested_tool_out", default=None)
    a("--container", default=None, required=False)
    a("--tool_conf_path", default="config/tool_conf.xml")  # relative to $__root_dir__
    a(
        "--xtra_files",
        default=[],
        action="append",
    )  # history data items to add to the tool base directory
    tfcl = sys.argv[1:]
    args = parser.parse_args()
    if args.admin_only:
        assert not args.bad_user, (
            'UNAUTHORISED: %s is NOT authorized to use this tool until Galaxy admin adds %s to "admin_users" in the galaxy.yml Galaxy configuration file'
            % (args.bad_user, args.bad_user)
        )
    assert (
        args.tool_name
    ), "## This ToolFactory cannot build a tool without a tool name. Please supply one."
    os.makedirs(args.tfcollection, exist_ok=True)
    logfilename = os.path.join(
        args.tfcollection, "ToolFactory_make_%s_log.txt" % args.tool_name
    )
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(logfilename, mode="w")
    fformatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    fh.setFormatter(fformatter)
    logger.addHandler(fh)
    tf = Tool_Factory(args)
    tf.makeTool()
    tf.writeShedyml()
    # tf.writeTFyml()tf.writeTFyml()
    tf.update_toolconf()
    time.sleep(5)
    if tf.condaenv and len(tf.condaenv) > 0:
        res = tf.install_deps()
        if res > 0:
            logger.debug("Toolfactory installed deps failed")
            logging.shutdown()
            sys.exit(6)
        time.sleep(2)
    testret = tf.planemo_local_test()  # fast_local_test()
    if False and int(testret) > 0:
        logger.error("ToolFactory tool build and test failed. :(")
        logger.info(
            "This is usually because the supplied script or dependency did not run correctly with the test inputs and parameter settings"
        )
        logger.info("when tested with galaxy_tool_test.  Error code:%d" % int(testret))
        logger.info(
            "The 'i' (information) option shows how the ToolFactory was called, stderr and stdout, and what the command line was."
        )
        logger.info(
            "Expand (click on) any of the broken (red) history output titles to see that 'i' button and click it"
        )
        logger.info(
            "Make sure it is the same as your working test command line and double check that data files are coming from and going to where they should"
        )
        logger.info(
            "In the output collection, the tool xml <command> element must be the equivalent of your working command line for the test to work"
        )
        logging.shutdown()
        sys.exit(5)
    else:
        tf.makeToolTar(testret)
        jcl = sys.argv[1:]
        with open(
            os.path.join(
                args.tfcollection, "ToolFactory_%s_commandline.json" % args.tool_name
            ),
            "w",
        ) as fout:
            fout.write(" ".join(jcl))
    logging.shutdown()


if __name__ == "__main__":
    main()
