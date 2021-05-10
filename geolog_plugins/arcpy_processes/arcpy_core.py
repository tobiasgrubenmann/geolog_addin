# Arcpy Util
#
# Author: Tobias Grubenmann
# Email: grubenmann@cs.uni-bonn.de
# Copyright: (C) 2020 Tobias Grubenmann


import uuid

import geolog_core.interpreter
import geolog_core.predicate
import geolog_core.util


class UUID(geolog_core.predicate.DeterministicPredicate):
    """Returns a uuid compatible with arcpy."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "uuid"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "arcpy_util"

    @classmethod
    def _get_predicate_function(cls):
        return cls.get_uuid

    @classmethod
    def get_uuid(cls, output):
        cls.unify(output.value, str(uuid.uuid4()).replace('-', '_'))
        return True


class ArcSDEExecutePredicate(geolog_core.predicate.DeterministicPredicate):
    """Executes an ArcSDE SQL query."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "executeArcSDE"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "arcpy_util"

    @classmethod
    def _get_predicate_function(cls):
        return cls.execute_query

    @classmethod
    def execute_query(cls, connection, query, result=None):
        cls.print_query(query)
        try:
            if result:
                result_list = connection.execute(query)
                cls.unify(result.value, result_list)
            else:
                connection.execute(query)
            return True
        except AttributeError:
            return False

    @classmethod
    def print_query(cls, query):
        if geolog_core.interpreter.Interpreter().trace:
            print("SQL QUERY: " + str(query))


class ArcSDEExecuteIteratorPredicate(geolog_core.predicate.DeterministicPredicate):
    """Iterator over the result of an ArcSDE SQL query."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "executeArcSDEIterator"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "arcpy_util"

    @classmethod
    def _get_predicate_function(cls):
        return cls.execute_query

    @classmethod
    def execute_query(cls, connection, query, result):
        cls.print_query(query)
        try:
            query_result = connection.execute(query)
            # return value true means valid query but no result
            if query_result is True:
                query_result = []
            else:
                # Single values must be formatted correctly
                if not isinstance(query_result, list):
                    query_result = [[query_result]]
            iterator = iter(query_result)
            cls.unify(result.value, iterator)
            return True
        except AttributeError:
            return False
        except TypeError:
            return False

    @classmethod
    def print_query(cls, query):
        if geolog_core.interpreter.Interpreter().trace:
            print("SQL QUERY: " + str(query))
