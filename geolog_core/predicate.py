# Predicate
#
# Author: Tobias Grubenmann
# Email: grubenmann@cs.uni-bonn.de
# Copyright: (C) 2020 Tobias Grubenmann

import inspect
import pkgutil
import sys

import pyswip.core
import geolog_core.interpreter
import geolog_core.reference_manager
import geolog_core.util
import pyswip


class Predicate(object):
    """A SWI-Prolog foreign predicate."""

    @classmethod
    def is_deterministic(cls):
        return True

    @classmethod
    def get_reference_manager(cls):
        return geolog_core.reference_manager.ReferenceManager()

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return None

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return None

    @classmethod
    def _get_predicate_function(cls):
        """The function that implements the predicate.
           This is the only method that needs to be implemented."""
        return lambda *args: False  # This predicate will always fail and shouldn't be used.

    @classmethod
    def get_minimum_arity(cls):
        """The minimum number of arguments for the predicate.
           The predicate will be registered with arguments between get_minimum_arity() and get_minimum_arity()."""
        arity = 0
        (args, _, _, defaults) = inspect.getargspec(cls._get_predicate_function())
        if args:
            arity = len(args)
        if defaults:
            arity -= len(defaults)
        if inspect.ismethod(cls._get_predicate_function()):  # subtract 1 for first argument in a method
            arity -= 1
        return arity

    @classmethod
    def get_maximum_arity(cls):
        """The maximum number of arguments for the predicate.
           The predicate will be registered with arguments between get_minimum_arity() and get_minimum_arity()."""
        arity = 0
        (args, _, _, _) = inspect.getargspec(cls._get_predicate_function())
        if args:
            arity = len(args)
        if inspect.ismethod(cls._get_predicate_function()):  # subtract 1 for first argument in a method
            arity -= 1
        return arity

    @classmethod
    def execute(cls, *args):
        """Executes a given function and handles management of atoms."""
        return cls._get_predicate_function()(*args)

    @classmethod
    def _dereference(cls, value):
        return_value = value
        if type(value) == pyswip.Atom:
            if value.value == "true":
                return_value = True
            elif value.value == "false":
                return_value = False
            elif value.value == "none":
                return_value = None
            else:
                return_value = cls.get_reference_manager().get(value)
        elif type(value) == list:
            return_value = []
            for element in value:
                return_value.append(cls._dereference(element))

        return return_value

    @classmethod
    def unify(cls, arg, value):
        if isinstance(arg, (list, tuple)):
            for i in range(len(arg)):
                cls.unify(arg[i], value[i])
        elif isinstance(arg, pyswip.Variable):
            # prepare variable for unification
            if isinstance(value, (list, tuple)):
                # tuples need to be converted to lists
                arg.value = cls._iterable_to_list(value)
            elif not isinstance(value, geolog_core.util.prolog_types):
                # non-Prolog types need to be stored and referenced through an atom
                new_atom = cls.get_reference_manager().create_atom()
                cls.get_reference_manager().put(new_atom, value)
                arg.value = new_atom
            else:
                arg.value = value

    @classmethod
    def _iterable_to_list(cls, iterable):
        result_list = []
        for i in range(len(iterable)):
            try:
                if isinstance(iterable[i], (str, unicode)):
                    # prevent infinite loop with strings
                    result_list.append(iterable[i])
                else:
                    result_list.append(cls._iterable_to_list(iterable[i]))
            except TypeError:
                if isinstance(iterable[i], geolog_core.util.prolog_types):
                    result_list.append(iterable[i])
                else:
                    # non-Prolog types need to be stored and referenced through an atom
                    new_atom = cls.get_reference_manager().create_atom()
                    cls.get_reference_manager().put(new_atom, iterable[i])
                    result_list.append(new_atom)

        return result_list

    @classmethod
    def trace(cls):
        """Prints a trace if flag is set in interpreter."""
        if geolog_core.interpreter.Interpreter().trace:
            print("CALL: " + str(cls.get_module_name()) + ":" + str(cls.get_predicate_name()))


class DeterministicPredicate(Predicate):
    """Used for deterministic predicates. Deterministic predicates return one solution (or none)."""

    @classmethod
    def _get_predicate_function(cls):
        """The function that implements the predicate.
           This is the only method that needs to be implemented."""
        return lambda *args: False  # This predicate will always fail and shouldn't be used.

    @classmethod
    def execute(cls, *args):
        """Executes a given function and handles management of atoms."""

        cls.trace()

        function = cls._get_predicate_function()

        new_args = cls._dereference(list(args))

        return_value = function(*new_args)

        return return_value


class Delete(Predicate):
    """Deletes an object."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "delete"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def delete(cls, object):
        """Executes a given function and handles management of atoms."""
        cls.trace()
        geolog_core.reference_manager.ReferenceManager().clear(object)

    @classmethod
    def _get_predicate_function(cls):
        """The function that implements the predicate.
           This is the only method that needs to be implemented."""
        return cls.delete


class GetAttribute(DeterministicPredicate):
    """Returns the attribute of an object."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "get_attribute"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def _get_predicate_function(cls):
        return cls.get_attribute

    @classmethod
    def get_attribute(cls, obj, attribute_name, attribute):
        if hasattr(obj, attribute_name):
            cls.unify(attribute, getattr(obj, attribute_name))
            return True
        return False


class SetAttribute(DeterministicPredicate):
    """Sets the attribute of an object."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "set_attribute"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def _get_predicate_function(cls):
        return cls.set_attribute

    @classmethod
    def set_attribute(cls, obj, attribute_name, attribute):
        if hasattr(obj, attribute_name):
            setattr(obj, attribute_name, attribute)
            return True
        return False


class CallMethod(DeterministicPredicate):
    """Calls a method of an object."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "call_method"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def _get_predicate_function(cls):
        return cls.call_method

    @classmethod
    def call_method(cls, obj, method_name, arg_list=None, output=None):
        successful = False
        if hasattr(obj, method_name):
            method = getattr(obj, method_name)
            if callable(method):
                if arg_list:
                    if output:
                        cls.unify(output, method(*arg_list))
                    else:
                        method(*arg_list)
                else:
                    if output:
                        cls.unify(output, method())
                    else:
                        method()
                successful = True
        return successful


class IteratorPredicate(Predicate):
    """Non-deterministic iterator over an object."""

    @classmethod
    def is_deterministic(cls):
        return False

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "iterate"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def execute(cls, iterator_atom, item, handle):
        """Executes one iteration of the iterator.
           Binds item_variable to a single value or list of values."""

        cls.trace()

        control = cls.get_control(handle)
        return_value = False

        iterator = cls.get_reference_manager().get(iterator_atom)

        if control == cls.get_first_call() or control == cls.get_redo():
            try:
                cls.unify(item, cls.get_next(iterator))
                return_value = cls.retry(0)
            except StopIteration:
                return_value = False

        return return_value

    @classmethod
    def get_next(cls, iterator):
        return iterator.next()

    @classmethod
    def get_minimum_arity(cls):
        return 2

    @classmethod
    def get_maximum_arity(cls):
        return 2

    @classmethod
    def get_control(cls, handle):
        return pyswip.core.PL_foreign_control(handle)

    @classmethod
    def get_first_call(cls):
        return pyswip.core.PL_FIRST_CALL

    @classmethod
    def get_redo(cls):
        return pyswip.core.PL_REDO

    @classmethod
    def get_pruned(cls):
        return pyswip.core.PL_PRUNED

    @classmethod
    def retry(cls, value):
        return pyswip.core.PL_retry(value)

    @classmethod
    def get_address(cls, handle):
        return pyswip.core.PL_foreign_context_address(handle)


class NextPredicate(Predicate):
    """Deterministic iterator over an object."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "next"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def execute(cls, iterator_atom, item):
        """Executes one iteration of the iterator.
           Binds item_variable to a single value or list of values."""

        cls.trace()

        return_value = False

        iterator = cls.get_reference_manager().get(iterator_atom)

        try:
            cls.unify(item, next(iterator))
            return_value = True
        except StopIteration:
            del iterator
            cls.get_reference_manager().clear(iterator_atom)

        return return_value

    @classmethod
    def get_minimum_arity(cls):
        return 2

    @classmethod
    def get_maximum_arity(cls):
        return 2


class GetByIndex(DeterministicPredicate):
    """Retrieve an object from a collection by index."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "get_by_index"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def _get_predicate_function(cls):
        return cls.get_by_index

    @classmethod
    def get_by_index(cls, collection, index, item):
        """returns the object designated by the index."""
        return_value = False
        if index < len(collection):
            cls.unify(item, collection[index])
            return_value = True
        return return_value


class Iterator(DeterministicPredicate):
    """Creates a new iterator over a collection."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "iterator"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def _get_predicate_function(cls):
        return cls.iterator

    @classmethod
    def iterator(cls, collection, iterator):
        """returns the object designated by the index."""
        return_value = True
        try:
            cls.unify(iterator, iter(collection))
        except TypeError:
            return_value = False
        return return_value


class Replace(DeterministicPredicate):
    """Returns the attribute of an object."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "replace"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "geolog"

    @classmethod
    def _get_predicate_function(cls):
        return cls.replace

    @classmethod
    def replace(cls, find_substring, replace_with_substring, input_string, output_string):
        output_string.value = input_string.replace(find_substring, replace_with_substring)
        return True


def get_classes_from_paths(path_package_pairs, classes):
    for (paths, base_package) in path_package_pairs:
        for path in paths:
            for importer, name, is_package in pkgutil.iter_modules([path]):
                if name != "tests":
                    _import(importer, name, classes, base_package)
                    if is_package:
                        get_classes_from_paths([([path + "/" + name], base_package + "." + name)], classes)


def _import(importer, module_name, classes, base_package):
    full_name = base_package
    if module_name:
        full_name += "." + module_name
    if full_name not in sys.modules:
        loader = importer.find_module(full_name)
        module = loader.load_module(full_name)
    else:
        module = sys.modules[full_name]

    for _, cls in inspect.getmembers(module, inspect.isclass):
        if hasattr(cls, Predicate.get_predicate_name.__name__) and \
                hasattr(cls, Predicate.get_reference_manager.__name__) and \
                hasattr(cls, Predicate.execute.__name__) and \
                hasattr(cls, Predicate.get_minimum_arity.__name__) and \
                hasattr(cls, Predicate.get_maximum_arity.__name__) and \
                hasattr(cls, Predicate.is_deterministic.__name__) and \
                cls not in classes:
            classes.add(cls)

