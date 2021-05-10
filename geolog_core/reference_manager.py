# Reference Manager
#
# Author: Tobias Grubenmann
# Email: grubenmann@cs.uni-bonn.de
# Copyright: (C) 2020 Tobias Grubenmann

import threading

import geolog_core.util
import pyswip


lock = threading.Lock()


class Singleton(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            with lock:
                if cls not in cls._instances:
                    cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]


class ReferenceManager(object):

    __metaclass__ = Singleton

    def __init__(self):
        self._object_dict = {}

    def create_atom(self):
        atom_name = geolog_core.util.get_new_uuid()
        return pyswip.Atom(atom_name)

    def put(self, key, value):
        self._object_dict[key] = value

    def get(self, key):
        return self._object_dict[key]

    def clear(self, key):
        if key in self._object_dict:
            del self._object_dict[key]

    def reset(self):
        self._object_dict = {}
