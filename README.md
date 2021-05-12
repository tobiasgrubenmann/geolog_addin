# Geolog ArcMap Addin

## Setup

1. Install ArcMap 10.8 or higher. (Tested on 10.8 and 10.8.1, but should work on 10.3 and higher)
2. Install SWI-Prolog, 32-bit version, and make sure that it is added to the PATH variable. (Tested on SWI-Prilog 8.2.4)
3. Install the Geolog Addin located in the bin folder.

## Verifying the Installation

To verify that GEolog is correclty set up, open the "Geolog Toolbar" under "Customize" -> "Toolbars" and click on "Query". Then, type in the following query:

    X = 1

You should get the following solution (indicating that unifying X with the literal 1 is a solution):

    [{'X': 1}]

## Usage

Once installed, a new toolbar called "Geolog Toolbar" is available under "Customize" -> "Toolbars". The Geolog toolbar consists of two buttons, "Consult" and "Query".

The "Consult" button is used to load (or consult) a prolog file. Once a prolog file is loaded, the corresponding predicates are available for querying. Geolog already provides out of the box a plethora of predicates which integrate with ArcMap.

The "Query" button is used to submit queries to prolog. Some predicates might also produce side-effects during querying, like creating a new Feature Class or a new selection.

## Built-in Predicates

The following predicates are provided by Geolog out of the box.

### Geolog Core Predicates

The following predicates help to interact with Python objects:

* `geolog:delete(+Object)`: Deletes the Python object referenced by the atom in `Object`.
* `geolog:get_attribute(+Object, +Attribute_name, -Attribute)`: Returns an attribute from a Python object.
* `geolog:set_attribute(+Object, +Attribute_name, -Attribute)`: Sets an attribute from a Python object.
* `geolog:call_method(+Object, +Method_name, +Arg_list, -Result)`: Calls a method indicated by the name as a string and arguments provided as list.
* `geolog:iterate(+Iterator, +Item)`: Iterates over an iterator and returns the items.
* `geolog:next(+Iterator, +Item)`: Returns the next item from an iterator.
* `geolog:get_by_index(+Collection, +Index, -Item)`: Returns item at position `Index` from `Collection`.
* `geolog:iterator(+Collection, -Iterator)`: Returns a new iterator over `Collection`.
* `geolog:replace(+Find_substring, + Replace_with_substring, +Input_string, -Output_string))`: Replaces all instances of `Find_substring` with `Replace_with_substring` in `Input_string` and returns the result as `Output_string`.

### Arcpy Core Predicates

All classes and functions available in Arcpy are mapped to a corresponding predicate in Geolog. The following template is used for mapping functions with a return value and class constructors:

    arcpy_core:'full_qualified_name'([Parameter1, ..., ParamterN], ReturnValue)
    
The following template is used for mapping functions without a return value:

    arcpy_core:'full_qualified_name'([Parameter1, ..., ParamterN])
    
The full qualified name must be put inot single quotes ('), as it may contain dots (.), which has to be quoted in Prolog. If the function/constructor does not have any paramters, an empty list has to be used. If there is no return value it can be ommitted.

### Arcpy Util Predicates

In addition to the arcpy core predicates, which directly correspond to arcpy functions and constructors, Geolog provides the following helper predicates.

* `arcpy_util:uuid(-UUID)`: returns a universal unique id in a format that is compatible with various arcpy functions. (xxxxxxxx_xxxx_xxxx_xxxx_xxxxxxxxxxxx)
* `arcpy_util:sql_query_result(Query)(+Query)`, `arcpy_util:sql_query_result(+Query, -Result)`: Runs `Query` if a DB connection is set up, otherwise writes the query to std out.
* `arcpy_util:sql_query_iterator(+Connection, -Iterator)`: Runs `Query` if a DB connection is set up and returns an iterator over the result. If no DB connection is set up, writes the query to std out and returns an iterator over the empty list.
* `arcpy_util:extract_selection(+Layer, -Selection)`: Creates a new feature class from a layer based on the selection. The selection is cleared during the process.
* `arcpy_util:add_layer(Features, LayerName)`: Adds the features as a new layer with the name LayerName to the current map.

### Postgres Geodatabse predicates

The following predicates facilitate the interaction with a Geodatabase (ArcSDE) on top of Postgres.

* `postgres:within_distance((?Relation1, ?Id1), (?Relation2, ?Id2), +Radius)`: True if `(Relation1, Id1)` is not farther than `Radius` from `(Relation2, Id2)`.
* `postgres:within_distance_relational(?Relation1, ?Relation2, -Output, +Radius, [+FieldName1, +FieldName2])`: True if `Output` contains in `FieldName1` and `FieldName2` all the keys from `Relation1` and `Relation2`, respectively, such that the entities are not farther away than `Radius1`.
* `postgres:intersect((?Relation1, ?Id1), (?Relation2, ?Id2))`: True if `(Relation1, Id1)` intersects `(Relation2, Id2)`.
* `postgres:intersect_relational(?Relation1, ?Relation2, -Output, +Radius, [+FieldName1, +FieldName2])`: True if `Output` contains in `FieldName1` and `FieldName2` all the keys from `Relation1` and `Relation2`, respectively, such that the entities intersect.
* `postgres:minus_table(+Relation1, +Relation2, -Output)`: Returns a new relation which is the difference between `Relation1` and `Relation2`.
* `project_id_relational(+Relation, +Fields, -Output)`: Returns as a new relation the relation `Relation` projected on the list of fields in `Fields`.
* `join_relational(+Relation1, +Relation2, -Output, +Attribute1, +Attribute2, +Fields)`: Joins `Relation1` with `Relation2` on `Attribute1` and `Attribute2` and maps fields according to `Fields`.
* `iterate_table(+Relation, -Row)`: Returns all IDs in a relation.
* `filter_by_relationship(+Relation, +Relationship, +Attribute, -Output)`: Filters `Relation` according to the IDs in Relationship. Attribute must point to a field in `Relationship`.
* `materialize(+Relation, +FeatureClass)`: Copies the (temporary) relation into a new in-memory Feature Class.

## Using a DB connection to Postgres

To use a Postgres Geodatabase (ArcSDE), you need to tell Geolog how it can connect to the database. For this, run the following query:

    designated:initialize_db_connection('C:\path\to\ConnectionFile.sda, run)
    
In addition, you need to tell Geolog the names of the tables it is allowed to use. For this, run the following query:

    designated:relation_key("table_name", "table_key").
    
The second parameter, "table_key", tells Geolog which column is uniquely identifying the entities within a table. Make sure that this ID is consistent throughout different tables.