import arcpy
import os
import sys

from pyswip.prolog import PrologError

sys.path.append(os.path.dirname(__file__))
from geolog_core.interpreter import Interpreter


class Toolbox(object):
    def __init__(self):
        self.tools = [ConsultTool, QueryTool]


class ConsultTool(object):
    def __init__(self):
        self.label = "Consult File"
        self.description = "The specified file(s) will be loaded (consulted) by the Prolog interpreter."
        self.canRunInBackground = False

    def getParameterInfo(self):
        parameter = arcpy.Parameter(
            displayName="Input File(s)",
            name="input_files",
            datatype="DEFile",
            parameterType="Required",
            direction="Input",
            multiValue=True)
        parameter.filter.list = ["pl"]
        return [parameter]

    def isLicensed(self):
        return True

    def updateParameters(self, parameters):
        pass

    def updateMessages(self, parameters):
        pass

    def execute(self, parameters, messages):
        for value_object in parameters[0].values:
            Interpreter().consult(value_object.value)


class QueryTool(object):
    def __init__(self):
        self.label = "Query"
        self.description = "Runs the query against the consulted DB."
        self.canRunInBackground = False

    def getParameterInfo(self):
        parameter = arcpy.Parameter(
            displayName="Query",
            name="query",
            datatype="GPString",
            parameterType="Required",
            direction="Input")
        return [parameter]

    def isLicensed(self):
        return True

    def updateParameters(self, parameters):
        pass

    def updateMessages(self, parameters):
        pass

    def execute(self, parameters, messages):
        try:
            query = parameters[0].value
            result = Interpreter().query(query, debug=True)
            messages.AddMessage(str(result))
        except PrologError as e:
            messages.AddMessage("PROLOG ERROR: {0}".format(str(e)))
        except AttributeError as e:
            messages.AddMessage("ATTRIBUTE ERROR: {0}".format(str(e)))
        except Exception as e:
            messages.AddMessage("ERROR: {0}".format(str(e)))
