import sys
import os

import arcpy
import pythonaddins

# add all addin root folders to path
for dir_name in os.listdir(os.path.join(os.path.dirname(__file__), os.pardir)):
    dir_path = os.path.join(os.path.join(os.path.dirname(__file__), os.pardir), dir_name)
    if os.path.isdir(dir_path):
        sys.path.insert(0, os.path.normpath(dir_path))
#sys.path.append(os.path.dirname(__file__))

import geolog_core.interpreter

tool_path = os.path.join(os.path.dirname(__file__), "arcmap_toolbox/ArcPrologToolbox.pyt")


class ConsultButtonClass(object):
    """Implementation for arcprolog.consult_button (Button)"""

    def __init__(self):
        self.enabled = True
        self.checked = False

    def onClick(self):
        pythonaddins.GPToolDialog(tool_path, "ConsultTool")


class QueryButtonClass(object):
    """Implementation for arcprolog.query_button (Button)"""

    def __init__(self):
        self.enabled = True
        self.checked = False

    def onClick(self):
        pythonaddins.GPToolDialog(tool_path, "QueryTool")

class ResetButtonClass(object):
    """Implementation for arcprolog.reset_button (Button)"""

    def __init__(self):
        self.enabled = True
        self.checked = False

    def onClick(self):
        geolog_core.interpreter.Interpreter().reset()
