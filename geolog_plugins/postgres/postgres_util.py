# Postgres Util
#
# Author: Tobias Grubenmann
# Email: grubenmann@cs.uni-bonn.de
# Copyright: (C) 2020 Tobias Grubenmann


import geolog_core.predicate


class RemoveTableNamePredicate(geolog_core.predicate.DeterministicPredicate):
    """Removes the table name (separated by a '.') from an input string."""

    @classmethod
    def get_predicate_name(cls):
        """The name of the predicate in Prolog."""
        return "remove_table_name"

    @classmethod
    def get_module_name(cls):
        """The module of the predicate in Prolog."""
        return "postgres_util"

    @classmethod
    def _get_predicate_function(cls):
        return cls.remove

    @classmethod
    def remove(cls, input_string, output_string):
        cls.unify(output_string.value, input_string.split(".")[-1])
        return True
