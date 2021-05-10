# Interpreter
#
# Author: Tobias Grubenmann
# Email: grubenmann@cs.uni-bonn.de
# Copyright: (C) 2020 Tobias Grubenmann

import os.path
import threading

import geolog_core
import pyswip
import pyswip.core

import geolog_core.predicate
import geolog_core.reference_manager
import geolog_plugins

lock = threading.Lock()

escape_dict = {"\\": "/", "{": "[{]", "}": "[}]", "[": "[[]", "]": "{]}", "$": "[$]"}


class Singleton(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            with lock:
                if cls not in cls._instances:
                    cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]


class Interpreter(object):
    """Interacts with the Prolog interpreter."""

    __metaclass__ = Singleton

    def __init__(self):

        self.trace = False

        self.prolog = pyswip.Prolog()

        # load geolog_plugins
        self.plugins = [(geolog_plugins.__path__, "geolog_plugins"),
                        (geolog_core.__path__, "geolog_core")]
        self.classes = set()
        self.load_plugins()
        self.load_prolog_files()

        # setup for xpce
        self.query("[swi('swipl-win.rc')]")

        # set gui tracer
        self.query("guitracer")

    def add_plugin(self, path, package):
        self.plugins.append(([path], package))
        self.load_plugins()
        self.load_prolog_files()

    def load_plugins(self):
        self.classes = set()
        geolog_core.predicate.get_classes_from_paths(self.plugins, self.classes)
        for cls in self.classes:
            if cls.get_predicate_name():

                for arity in range(cls.get_minimum_arity(), cls.get_maximum_arity() + 1):
                    if cls.is_deterministic():
                        pyswip.registerForeign(cls.execute, name=cls.get_predicate_name(), arity=arity,
                                               module=cls.get_module_name())
                    else:
                        pyswip.registerForeign(cls.execute, name=cls.get_predicate_name(), arity=arity,
                                               flags=pyswip.core.PL_FA_NONDETERMINISTIC, module=cls.get_module_name())

    def load_prolog_files(self):
        for plugin_paths, _ in self.plugins:
            for plugin_path in plugin_paths:
                for path, _, files in os.walk(plugin_path):
                    for name in files:
                        if name.endswith(".pl"):
                            self.consult(os.path.join(path, name))

    def consult(self, file_name, catch_errors=True):
        """Consults a file and loads it into the Prolog instance."""
        # Escape \ and wildcards
        cleaned_file_name = ""
        for char in file_name:
            if char in escape_dict:
                cleaned_file_name += escape_dict[char]
            else:
                cleaned_file_name += char

        self.prolog.consult(cleaned_file_name, catcherrors=catch_errors)

    def query(self, query, catch_errors=True, debug=False):
        """Executes a Prolog query."""
        result = list(self.prolog.query(query, catcherrors=catch_errors, debug=debug))
        if not result:
            result = False
        elif result == [{}]:
            result = True
        return result

