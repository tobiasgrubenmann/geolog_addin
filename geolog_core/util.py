# Util
#
# Author: Tobias Grubenmann
# Email: grubenmann@cs.uni-bonn.de
# Copyright: (C) 2020 Tobias Grubenmann

import uuid

import pyswip

prolog_types = (pyswip.Variable, pyswip.Atom, pyswip.Functor, str, unicode, int, float, bool, list)


def get_new_uuid():
    return str(uuid.uuid4()).replace('-', '_')
