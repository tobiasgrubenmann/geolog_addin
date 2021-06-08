import os

import arcpy

import geolog_core.interpreter
import pyswip.prolog


if __name__ == "__main__":
    # arcpy.MakeFeatureLayer_management("C:/Users/Tobias/Documents/Documents Uni Bonn/Projects/SimpleML/GeoProlog/Python/geolog_plugins/arcpy_processes/tests/shapefiles/lines.shp", "lines")
    # arcpy.MakeFeatureLayer_management("C:/Users/Tobias/Documents/Documents Uni Bonn/Projects/SimpleML/GeoProlog/Python/geolog_plugins/arcpy_processes/tests/shapefiles/points.shp", "points")
    # arcpy.MakeFeatureLayer_management("C:/Users/Tobias/Documents/Documents Uni Bonn/Projects/SimpleML/GeoProlog/Python/geolog_plugins/arcpy_processes/tests/shapefiles/segments.shp", "segments")

    test_interpreter = geolog_core.interpreter.Interpreter()
    # file_name = os.path.normpath(os.path.join(os.path.split(os.path.abspath(__file__))[0], "../../../../Prolog/AccidentAnalysis/spatial_relations.pl"))
    # test_interpreter.consult(file_name)
    # file_name = os.path.normpath(os.path.join(os.path.split(os.path.abspath(__file__))[0],
    #                                           "../../../../Prolog/AccidentAnalysis/setup.pl"))
    # test_interpreter.consult(file_name)
    try:
        print(test_interpreter.query("arcpy_core:'arcpy.Exists'([\"test\"], Result)", debug=True))
    except pyswip.prolog.PrologError as e:
        print("ERROR: {0}".format(str(e)))
