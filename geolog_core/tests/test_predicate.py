import unittest

import geolog_core.predicate
import geolog_core.reference_manager
import pyswip


class TestPredicate(unittest.TestCase):

    def test_get_predicate_name(self):
        self.assertEqual('test_me', DeterministicDummyProcess.get_predicate_name())

    def test_get_predicate_function(self):
        self.assertEqual(DeterministicDummyProcess.test, DeterministicDummyProcess._get_predicate_function())

    def test_get_minimum_arity(self):
        self.assertEqual(2, DeterministicDummyProcess.get_minimum_arity())

    def test_get_maximum_arity(self):
        self.assertEqual(4, DeterministicDummyProcess.get_maximum_arity())

    def test_execute_deterministic_with_variable_integer(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        variable = pyswip.Variable()

        IntegerDeterministicDummyProcess.execute(variable)

        self.assertEqual({}, geolog_core.reference_manager.ReferenceManager()._object_dict)
        self.assertEqual(123, variable.value)

    def test_execute_deterministic_with_variable_string(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        variable = pyswip.Variable()

        StringDeterministicDummyProcess.execute(variable)

        self.assertEqual({}, geolog_core.reference_manager.ReferenceManager()._object_dict)
        self.assertEqual("test_me", variable.value)

    def test_execute_deterministic_with_variable_atom(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        variable = pyswip.Variable()

        ObjectDeterministicDummyProcess.execute(variable)

        atom = geolog_core.reference_manager.ReferenceManager()._object_dict.keys()[0]

        self.assertEqual(DummyObject(1), geolog_core.reference_manager.ReferenceManager()._object_dict[atom])
        self.assertEqual(atom, variable.value)

    def test_execute_deterministic_with_list(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        variable_1 = pyswip.Variable()
        variable_2 = pyswip.Variable()
        variable_3 = pyswip.Variable()
        variables = [variable_1, variable_2, variable_3]

        ListDeterministicDummyProcess.execute(variables)

        atom = geolog_core.reference_manager.ReferenceManager()._object_dict.keys()[0]

        self.assertEqual(DummyObject(1), geolog_core.reference_manager.ReferenceManager()._object_dict[atom])
        self.assertEqual(123, variables[0].value)
        self.assertEqual("test_me", variables[1].value)
        self.assertEqual(atom, variables[2].value)

    def test_execute_deterministic_with_list_of_lists_one_variable(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        variable = pyswip.Variable()

        ListOfListDeterministicDummyProcess.execute(variable)

        self.assertEqual([[1, 2], [3, 4]], variable.value)

    def test_execute_deterministic_with_list_of_lists_multiple_variables(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        variable_1 = pyswip.Variable()
        variable_2 = pyswip.Variable()

        ListOfListDeterministicDummyProcess.execute([variable_1, variable_2])

        self.assertEqual([1, 2], variable_1.value)
        self.assertEqual([3, 4], variable_2.value)

    def test_execute_deterministic_with_atom(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        atom = pyswip.Atom("test_me")
        geolog_core.reference_manager.ReferenceManager()._object_dict[atom] = DummyObject(2)

        AtomDeterministicDummyProcess.execute(atom)

        self.assertEqual(DummyObject(2), AtomDeterministicDummyProcess.argument)
        self.assertTrue(isinstance(atom, pyswip.Atom))

    def test_iterator(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        DummyIterator.control = 0
        iterator_atom = pyswip.Atom("iterator")
        geolog_core.reference_manager.ReferenceManager()._object_dict[iterator_atom] = iter([1, 2, 3])

        variable = pyswip.Variable()
        DummyIterator.execute(iterator_atom, variable, 0)
        self.assertEqual(1, variable.value)

        variable = pyswip.Variable()
        DummyIterator.execute(iterator_atom, variable, 0)
        self.assertEqual(2, variable.value)

        variable = pyswip.Variable()
        DummyIterator.execute(iterator_atom, variable, 0)
        self.assertEqual(3, variable.value)

        variable = pyswip.Variable()
        return_value = DummyIterator.execute(iterator_atom, variable, 0)
        self.assertEqual(False, return_value)

    def test_iterator_prune(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        DummyIterator.control = 0
        iterator_atom = pyswip.Atom("iterator")
        geolog_core.reference_manager.ReferenceManager()._object_dict[iterator_atom] = iter([1, 2, 3])

        variable = pyswip.Variable()
        DummyIterator.execute(iterator_atom, variable, 0)

        DummyIterator.control = 2

        variable = pyswip.Variable()
        return_value = DummyIterator.execute(iterator_atom, variable, 0)
        self.assertFalse(return_value)

    def test_iterator_list(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        DummyIterator.control = 0
        iterator_atom = pyswip.Atom("iterator")
        geolog_core.reference_manager.ReferenceManager()._object_dict[iterator_atom] = iter([[1, 2], [2, 3], [3, 4]])

        variable = pyswip.Variable()
        DummyIterator.execute(iterator_atom, variable, 0)
        self.assertEqual([1, 2], variable.value)

    def test_iterator_list_nested_variables(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        DummyIterator.control = 0
        iterator_atom = pyswip.Atom("iterator")
        geolog_core.reference_manager.ReferenceManager()._object_dict[iterator_atom] = iter([[1, 2], [2, 3], [3, 4]])

        variable_1 = pyswip.Variable()
        variable_2 = pyswip.Variable()
        DummyIterator.execute(iterator_atom, [variable_1, variable_2], 0)
        self.assertEqual(1, variable_1.value)
        self.assertEqual(2, variable_2.value)

    def test_iterator_bind_list_of_objects_to_list(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        DummyIterator.control = 0
        iterator_atom = pyswip.Atom("iterator")
        geolog_core.reference_manager.ReferenceManager()._object_dict[iterator_atom] = iter([[DummyObject(1), 2]])

        variable_1 = pyswip.Variable()
        variable_2 = pyswip.Variable()
        DummyIterator.execute(iterator_atom, [variable_1, variable_2], 0)

        atom = geolog_core.reference_manager.ReferenceManager()._object_dict.keys()[1]

        self.assertEqual(DummyObject(1), geolog_core.reference_manager.ReferenceManager()._object_dict[atom])
        self.assertEqual(atom, variable_1.value)
        self.assertEqual(2, variable_2.value)

    def test_iterator_bind_list_of_objects_to_variable(self):
        geolog_core.reference_manager.ReferenceManager().reset()
        DummyIterator.control = 0
        iterator_atom = pyswip.Atom("iterator")
        geolog_core.reference_manager.ReferenceManager()._object_dict[iterator_atom] = iter([[DummyObject(1), 2]])

        variable = pyswip.Variable()
        DummyIterator.execute(iterator_atom, variable, 0)

        atom = geolog_core.reference_manager.ReferenceManager()._object_dict.keys()[1]

        self.assertEqual(DummyObject(1), geolog_core.reference_manager.ReferenceManager()._object_dict[atom])
        self.assertEqual([atom, 2], variable.value)

    def test_replace(self):
        variable = pyswip.Variable()

        geolog_core.predicate.Replace.execute("me", "all", "test_me_please", variable)

        self.assertEqual("test_all_please", variable.value)


class DummyIterator(geolog_core.predicate.IteratorPredicate):

    control = 0

    address = 0

    @classmethod
    def get_reference_manager(cls):
        return geolog_core.reference_manager.ReferenceManager()

    @classmethod
    def get_control(cls, handle):
        return cls.control

    @classmethod
    def get_first_call(cls):
        return 0

    @classmethod
    def get_redo(cls):
        return 1

    @classmethod
    def get_pruned(cls):
        return 2

    @classmethod
    def retry(cls, value):
        return 0

    @classmethod
    def get_address(cls, handle):
        return cls.address


class DeterministicDummyProcess(geolog_core.predicate.DeterministicPredicate):

    argument_1 = None

    @classmethod
    def get_predicate_name(cls):
        return "test_me"

    @classmethod
    def get_reference_manager(cls):
        return geolog_core.reference_manager.ReferenceManager()

    @classmethod
    def _get_predicate_function(cls):
        return cls.test

    @classmethod
    def test(cls, argument_1, argument_2, optional_1=None, optional_2=None, *args, **kwargs):
        pass


class IntegerDeterministicDummyProcess(DeterministicDummyProcess):

    @classmethod
    def _get_predicate_function(cls):
        return cls.test

    @classmethod
    def test(cls, argument):
        cls.argument = argument
        cls.unify(argument.value, 123)


class StringDeterministicDummyProcess(DeterministicDummyProcess):

    @classmethod
    def _get_predicate_function(cls):
        return cls.test

    @classmethod
    def test(cls, argument):
        cls.unify(argument, "test_me")


class ObjectDeterministicDummyProcess(DeterministicDummyProcess):

    @classmethod
    def _get_predicate_function(cls):
        return cls.test

    @classmethod
    def test(cls, argument):
        cls.unify(argument, DummyObject(1))


class ListDeterministicDummyProcess(DeterministicDummyProcess):

    @classmethod
    def _get_predicate_function(cls):
        return cls.test

    @classmethod
    def test(cls, argument):
        cls.unify(argument, [123, "test_me", DummyObject(1)])


class ListOfListDeterministicDummyProcess(DeterministicDummyProcess):

    @classmethod
    def _get_predicate_function(cls):
        return cls.test

    @classmethod
    def test(cls, argument):
        cls.unify(argument, [[1, 2], [3, 4]])


class AtomDeterministicDummyProcess(DeterministicDummyProcess):

    argument = None

    @classmethod
    def _get_predicate_function(cls):
        return cls.test

    @classmethod
    def test(cls, argument):
        cls.argument = argument


class DummyObject(object):
    def __init__(self, identifier):
        self.identifier = identifier

    def __eq__(self, other):
        if isinstance(other, DummyObject):
            return self.identifier == other.identifier
        return False
