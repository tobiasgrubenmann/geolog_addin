# Arcpy Processes
#
# Author: Tobias Grubenmann
# Email: grubenmann@cs.uni-bonn.de
# Copyright: (C) 2020 Tobias Grubenmann


import functools
import inspect
import pkgutil
import sys

import arcpy

import geolog_core.predicate

MAX_ARITY = 10
MODULE_NAME = "arcpy_core"


def get_classes_and_functions(path, functions, classes, base_package):

    pkg_importer = pkgutil.get_importer(path)
    _import(pkg_importer, None, functions, classes, base_package)

    for importer, module_name, is_package in pkgutil.iter_modules([path]):
        if is_package:
            get_classes_and_functions(path + "/" + module_name, functions, classes, base_package + "." + module_name)
        else:
            _import(importer, module_name, functions, classes, base_package)


def _import(importer, module_name, functions, classes, base_package):
    full_name = base_package
    if module_name:
        full_name += "." + module_name
    if full_name not in sys.modules:
        loader = importer.find_module(full_name)
        module = loader.load_module(full_name)
    else:
        module = sys.modules[full_name]

    for _, element in inspect.getmembers(module, lambda x: inspect.isclass(x) or inspect.isfunction(x)):
        if inspect.isclass(element):
            classes.add((element, full_name))
        else:
            functions.add((element, full_name))


def predicate_function_wrapper(function, _, arg_list, return_value=None):
    if return_value:
        geolog_core.predicate.Predicate.unify(return_value.value, function(*arg_list))
    else:
        function(*arg_list)
    return True


def predicate_constructor_wrapper(class_to_construct, _, arg_list, return_value):
    geolog_core.predicate.Predicate.unify(return_value, class_to_construct(*arg_list))
    return True


function_set = set()
class_set = set()

get_classes_and_functions(arcpy.__path__[0], function_set, class_set, "arcpy")

for (f, location) in function_set:
    (args, _, _, defaults) = inspect.getargspec(f)
    # one additional argument for the return value
    min_arity = 1
    max_arity = 2
    name = location.replace('.', '_') + "_" + f.func_name
    # use ESRI toolname, if available
    if "__esri_toolname__" in f.func_dict:
        name = location.replace('.', '_') + "_" + f.func_dict["__esri_toolname__"]
    globals()[name] = type(name,
                           (geolog_core.predicate.DeterministicPredicate,), {
                               "__doc__": "Class to register foreign predicate for: ." + name,
                               "get_predicate_name": classmethod(functools.partial(
                                   (lambda predicate_name, cls: predicate_name), name)),
                               "get_module_name": classmethod(
                                   lambda cls: MODULE_NAME),
                               "_get_predicate_function": classmethod(
                                   lambda cls: cls.predicate_function),
                               "predicate_function": classmethod(functools.partial(
                                   predicate_function_wrapper, f)),
                               "get_minimum_arity": classmethod(functools.partial(
                                   (lambda value, cls: value), min_arity)),
                               "get_maximum_arity": classmethod(functools.partial(
                                   (lambda value, cls: value), max_arity))
                           })

for (c, location) in class_set:
    min_arity = 2
    max_arity = 2
    name = location.replace('.', '_') + "_" + c.__name__
    globals()[name] = type(name,
                           (geolog_core.predicate.DeterministicPredicate,), {
                               "__doc__": "Class to register foreign predicate for: ." + name,
                               "get_predicate_name": classmethod(functools.partial(
                                   (lambda predicate_name, cls: predicate_name), name)),
                               "get_module_name": classmethod(
                                   lambda cls: MODULE_NAME),
                               "_get_predicate_function": classmethod(
                                   lambda cls: cls.predicate_function),
                               "predicate_function": classmethod(functools.partial(
                                   predicate_constructor_wrapper, c)),
                               "get_minimum_arity": classmethod(functools.partial(
                                   (lambda value, cls: value), min_arity)),
                               "get_maximum_arity": classmethod(functools.partial(
                                   (lambda value, cls: value), max_arity))
                           })
