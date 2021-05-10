:- module(postgres, [within_distance/3, within_distance_relational/5, intersect/2, intersect_relational/4,
                     minus_relational/3, project_id_relational/3, join_relational/6, join_relational/5,
                     join_relational/4, iterate_relational/2, iterate_ids/2, iterate_ids_random/3,
                     random_relation/3, filter_by_relationship/4,
                     select_where_query/3, select_where_query_relational/3, materialize/2]).

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Postgres
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Author: Tobias Grubenmann
	% Email: grubenmann@cs.uni-bonn.de
	% Copyright: (C) 2020-2021 Tobias Grubenmann
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%------------------------------------------------------------------------------
% within_distance((?Relation1, ?Id1), (?Relation2, ?Id2), +Radius):
%------------------------------------------------------------------------------
% True if (Relation1, Id1) is near (Relation2, Id2) according to Radius.

%within_distance((Relation1, Id1), (Relation2, Id2), Radius) :-

within_distance((Relation1, Id1), (Relation2, Id2), Radius) :-
    % Check input
    nonvar(Table1),   
    nonvar(Id1),
    nonvar(Table2),   % GKW: Test is always false: nonvar(Table1) -- Should be Relation2?
    nonvar(Id2),
    % Execute query
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
	run_select_within(Radius,Table1,Table2,IDField1,Id1,IDField2,Id2).

run_select_within(Radius,Table1,Table2,IDField1,Id1,IDField2,Id2) :-
	make_select_within(Radius,Table1,Table2,IDField1,Id1,IDField2,Id2,Query),
	arcpy_util:sql_query_result(Query, Result),
    ( Result = true 
    ; Result = 1
    ),
    !.
    
make_select_within(Radius,Table1,Table2,IDField1,Id1,IDField2,Id2,Query) :-
	atomics_to_string([
        "SELECT ST_DWithin(table1.shape, table2.shape, ",
        Radius,
        ") FROM ",
        Table1,
        " AS table1, ",
        Table2,
        " AS table2 WHERE table1.",
        IDField1,
        " = '",
        Id1,
        "' AND table2.",
        IDField2,
        " = '",
        Id2,
        "'"
    ], Query).
    
    
within_distance((Relation1, Id1), (Relation2, Id2), Radius) :-
    % Check input
    nonvar(Relation1),
    nonvar(Id1),
    var(Id2),
    % get table
    (var(Relation2) -> designated:designated_relation(Relation2) ; true),
    % Execute query
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
    atomics_to_string([
        "SELECT table2.",
        IDField2,
        " FROM ",
        Relation1,
        " AS table1, ",
        Relation2,
        " AS table2 WHERE table1.",
        IDField1,
        " = '",
        Id1,
        "' AND ST_Intersects(ST_Buffer(table1.shape, ",
        Radius,
        "), table2.shape)"
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, [Id2]).

within_distance((Relation1, Id1), (Relation2, Id2), Radius) :-
    % Check input
    var(Id1),
    nonvar(Relation2),
    nonvar(Id2),
    % exploit symmetry
    within_distance((Relation2, Id2), (Relation1, Id1), Radius).

within_distance((Relation1, Id1), (Relation2, Id2), Radius) :-
    % Check input
    var(Id1),
    var(Id2),
    % get table
    (var(Relation1) -> designated:designated_relation(Relation1) ; true),
    (var(Relation2) -> designated:designated_relation(Relation2) ; true),
    % Execute query
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
    atomics_to_string([
        "SELECT table1.",
        IDField1,
        ", table2.",
        IDField2,
        " FROM ",
        Relation1,
        " AS table1, ",
        Relation2,
        " AS table2 WHERE ST_Intersects(ST_Buffer(table1.shape, ",
        Radius,
        "), table2.shape)"
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, [Id1, Id2]).

%------------------------------------------------------------------------------
% within_distance_relational(+Table1, +Table2, -Output, +Radius, +[FieldName1, FieldName2]):
%------------------------------------------------------------------------------
% Returns as output a relationship-relation with all pair of IDs that are closer than Radius.

within_distance_relational(Relation1, Relation2, Output, Radius, [FieldName1, FieldName2]) :-
    % Check input
    nonvar(Relation1),
    nonvar(Relation2),
    var(Output),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " AS SELECT ",
        Relation1,
        ".",
        IDField1,
        " AS ",
        FieldName1,
        ", ",
        Relation2,
        ".",
        IDField2,
        " AS ",
        FieldName2,
        " FROM ",
        Relation1,
        ", ",
        Relation2,
        " WHERE ST_Intersects(ST_Buffer(",
        Relation1,
        ".shape, ",
        Radius,
        "), ",
        Relation2,
        ".shape)"
    ], Query),
    arcpy_util:sql_query_result(Query),
    % create indices
    create_index(Output, FieldName1),
    create_index(Output, FieldName2).

%------------------------------------------------------------------------------
% create_index(+Connection, +TableName, +IDField):
%------------------------------------------------------------------------------
% Creates a btree index on IDField of Tablename using Connection.

create_index(TableName, IDField) :-
    atomics_to_string([
        "CREATE INDEX ",
        TableName,
        "_ix_",
        IDField,
        " ON ",
        TableName,
        " USING btree (",
        IDField,
        " ASC NULLS LAST)"
    ], IndexQuery),
    arcpy_util:sql_query_result(IndexQuery).

%------------------------------------------------------------------------------
% intersect((?Relation1, ?Id1), (?Relation2, ?Id2)):
%------------------------------------------------------------------------------
% True if F(?Relation1, ?Id1) intersects (?Relation2, ?Id2).

intersect((Relation1, Id1), (Relation2, Id2)) :-
    % Check input
    nonvar(Relation1),
    nonvar(Id1),
    nonvar(Relation2),
    nonvar(Id2),
    % Execute query
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
    atomics_to_string([
        "SELECT ST_Intersects(table1.shape, table2.shape) FROM ",
        Relation1,
        " AS table1, ",
        Relation2,
        " AS table2 WHERE table1.",
        IDField1,
        " = '",
        Id1,
        "' AND table2.",
        IDField2,
        " = '",
        Id2,
        "'"
    ], Query),
    arcpy_util:sql_query_result(Query, Result),
    (Result = true ; Result = 1).

intersect((Relation1, Id1), (Relation2, Id2)) :-
    % Check input
    nonvar(Relation1),
    nonvar(Id1),
    var(Id2),
    % get table
    (var(Relation2) -> designated:designated_relation(Relation2) ; true),
    % Execute query
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
    atomics_to_string([
        "SELECT table2.",
        IDField2,
        " FROM ",
        Relation1,
        " AS table1, ",
        Relation2,
        " AS table2 WHERE table1.",
        IDField1,
        " = '",
        Id1,
        "' AND ST_Intersects(table1.shape, table2.shape)"
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, [Id2]).

intersect((Relation1, Id1), (Relation2, Id2)) :-
    % Check input
    var(Id1),
    nonvar(Relation2),
    nonvar(Id2),
    % exploit symmetry
    intersect((Relation2, Id2), (Relation1, Id1)).

intersect((Relation1, Id1), (Relation2, Id2)) :-
    % Check input
    var(Id1),
    var(Id2),
    % get table
    (var(Relation1) -> designated:designated_relation(Relation1) ; true),
    (var(Relation2) -> designated:designated_relation(Relation2) ; true),
    % Execute query
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
    atomics_to_string([
        "SELECT table1.",
        IDField1,
        ", table2.",
        IDField2,
        " FROM ",
        Relation1,
        " AS table1, ",
        Relation2,
        " AS table2 WHERE ST_Intersects(table1.shape, table2.shape)"
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, [Id1, Id2]).

%------------------------------------------------------------------------------
% intersect_relational(+Table1, +Table2, -Output, +[FieldName1, FieldName2]):
%------------------------------------------------------------------------------
% Returns as output a relationship-relation with all pair of IDs that intersect.

intersect_relational(Relation1, Relation2, Output, [FieldName1, FieldName2]) :-
    % Check input
    nonvar(Relation1),
    nonvar(Relation2),
    var(Output),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    designated:relation_key(Relation1, IDField1),
    designated:relation_key(Relation2, IDField2),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " AS SELECT ",
        Relation1,
        ".",
        IDField1,
        " AS ",
        FieldName1,
        ", ",
        Relation2,
        ".",
        IDField2,
        " AS ",
        FieldName2,
        " FROM ",
        Relation1,
        ", ",
        Relation2,
        " WHERE ST_Intersects(",
        Relation1,
        ".shape, ",
        Relation2,
        ".shape)"
    ], Query),
    arcpy_util:sql_query_result(Query),
    % create indices
    create_index(Output, "id_1"),
    create_index(Output, "id_2").

%------------------------------------------------------------------------------
% minus_table(+Input1, +Input2, -Output):
%------------------------------------------------------------------------------
% True if Output is Relation1 minus Relation2.

minus_relational(Relation1, Relation2, Output) :-
    % Check input
    nonvar(Relation1),
    nonvar(Relation2),
    var(Output),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " (LIKE ",
        Relation1,
        " INCLUDING INDEXES)"
    ], CreateQuery),
    arcpy_util:sql_query_result(CreateQuery),
    atomics_to_string([
        "INSERT INTO ",
        Output,
        " SELECT * FROM ",
        Relation1,
        " EXCEPT SELECT * FROM ",
        Relation2
    ], InsertQuery),
    arcpy_util:sql_query_result(InsertQuery).

%------------------------------------------------------------------------------
% project_id_relational(+Input, +Fields, -Output):
%------------------------------------------------------------------------------
% True if Output is Relation projected onto Fields.

project_id_relational(Relation, Fields, Output) :-
    % Check input
    nonvar(Relation),
    Fields = [_|_],
    var(Output),
    % concat fields
    concat_fields(Fields, FieldsString),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " AS  SELECT ",
        FieldsString,
        " FROM ",
        Relation
    ], InsertQuery),
    arcpy_util:sql_query_result(InsertQuery),
    create_indices(Output, Fields).

concat_fields([Head|Tail], Result) :-
    Head = [Field, NewName],
    concat_fields(Tail, IntermediateResult),
    (IntermediateResult = "" ->
        IntermediateResultWithComma = IntermediateResult ;
        atomics_to_string([
            ", ",
            IntermediateResult
        ], IntermediateResultWithComma)),
    atomics_to_string([
        Field,
        " AS ",
        NewName,
        IntermediateResultWithComma
    ], Result).

concat_fields([Head|Tail], Result) :-
    \+(Head = [_, _]),
    Head = Field,
    concat_fields(Tail, IntermediateResult),
    (IntermediateResult = "" ->
        IntermediateResultWithComma = IntermediateResult ;
        atomics_to_string([
            ", ",
            IntermediateResult
        ], IntermediateResultWithComma)),
    atomics_to_string([
        Field,
        IntermediateResultWithComma
    ], Result).

concat_fields([], Result) :-
    Result = "".

create_indices(Output, [Head|Tail]) :-
    [_, IDField] = Head,
    postgres_util:remove_table_name(IDField, CleanIDField),
    atomics_to_string([
        "CREATE INDEX ",
        Output,
        "_ix_",
        CleanIDField,
         " ON ",
        Output,
        " USING btree (",
        CleanIDField,
        " ASC NULLS LAST)"
    ], IdIndexQuery),
    arcpy_util:sql_query_result(IdIndexQuery),
    create_indices(Output, Tail).

create_indices(Output, [Head|Tail]) :-
    \+([_, _] = Head),
    postgres_util:remove_table_name(Head, CleanIDField),
    atomics_to_string([
        "CREATE INDEX ",
        Output,
        "_ix_",
        CleanIDField,
         " ON ",
        Output,
        " USING btree (",
        CleanIDField,
        " ASC NULLS LAST)"
    ], IdIndexQuery),
    arcpy_util:sql_query_result(IdIndexQuery),
    create_indices(Output, Tail).

create_indices(_, []).

%------------------------------------------------------------------------------
% join_relational(+Relation1, +Relation2, -Output, +Attribute1, +Attribute2, +Fields):
%------------------------------------------------------------------------------
% True if Output is the join between relationship-relation Relation1 and Relation2 when comparing Attribute1 with Attribute2.
% The column names are mapping according to Fields

join_relational(Relation1, Relation2, Output, Attribute1, Attribute2, Fields) :-
    % Check input
    nonvar(Relation1),
    nonvar(Relation2),
    var(Output),
    nonvar(Attribute1),
    nonvar(Attribute2),
    % concat fields
    concat_fields(Fields, FieldsString),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " AS SELECT ",
        FieldsString,
        " FROM ",
        Relation1,
        " AS rel1, ",
        Relation2,
        " AS rel2 WHERE rel1.",
        Attribute1,
        " = rel2.",
        Attribute2
    ], Query),
    arcpy_util:sql_query_result(Query),
    % create indices
    create_indices(Output, Fields).

%------------------------------------------------------------------------------
% join_relational(+Relation1, +Relation2, -Output, +Attribute, +Fields):
%------------------------------------------------------------------------------
% True if Output is the join between relationship-relation Relation1 and Relation2 on Attribute.
% The column names are mapping according to Fields

join_relational(Relation1, Relation2, Output, Attribute, Fields) :-
    join_relational(Relation1, Relation2, Output, Attribute, Attribute, Fields).

%------------------------------------------------------------------------------
% iterate_table(+Relation, -Row):
%------------------------------------------------------------------------------
% Iterates over all rows of a relation

iterate_relational(Relation, Row) :-
    % Check input
    (var(Relation) -> designated:designated_relation(Relation) ; true),
    % Execute query
    atomics_to_string([
        "SELECT *  FROM ",
        Relation
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, Row).

%------------------------------------------------------------------------------
% iterate_ids(+Relation, -Id):
%------------------------------------------------------------------------------
% Returns all IDs in Relation.

iterate_ids(Relation, Id) :-
    % test input
    var(Id),
    % get table
    (var(Relation) -> designated:designated_relation(Relation) ; true),
    % Execute query
    designated:relation_key(Relation, IDField),
    atomics_to_string([
        "SELECT table1.",
        IDField,
        " FROM ",
        Relation,
        " AS table1"
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, [Id]).

%------------------------------------------------------------------------------
% iterate_ids_random(+Relation, +Size, -Id):
%------------------------------------------------------------------------------
% Returns all IDs in Relation.

iterate_ids_random(Relation, Size, Id) :-
    % test input
    nonvar(Size),
    var(Id),
    % get table
    (var(Relation) -> designated:designated_relation(Relation) ; true),
    % Execute query
    designated:relation_key(Relation, IDField),
    atomics_to_string([
        "SELECT table1.",
        IDField,
        " FROM ",
        Relation,
        " AS table1 ORDER BY random() LIMIT ",
        Size
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, [Id]).
%   (
%       Size = 1 -> arcpy_util:sql_query_result(Query, Id);
%       (
%           arcpy_util:sql_query_iterator(Query, Result),
%           geolog:iterate(Result, [Id])
%       )
%    ).

%------------------------------------------------------------------------------
% random_relation(+Relation, +Size, -Output):
%------------------------------------------------------------------------------
% Returns a new relation with random selection.

random_relation(Relation, Size, Output) :-
    % test input
    nonvar(Size),
    var(Output),
    % get table
    (var(Relation) -> designated:designated_relation(Relation) ; true),
     % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " (LIKE ",
        Relation,
        " INCLUDING INDEXES)"
    ], CreateQuery),
    arcpy_util:sql_query_result(CreateQuery),
    atomics_to_string([
        "INSERT INTO ",
        Output,
        " SELECT * FROM ",
        Relation,
        " ORDER BY random() LIMIT ",
        Size
    ], InsertQuery),
    arcpy_util:sql_query_result(InsertQuery),
    designated:relation_key(Relation, IDField),
    assertz(designated:relation_key(Output, IDField)).
%    atomics_to_string([
%        "CREATE TEMP TABLE ",
%        Output,
%        " AS SELECT * FROM ",
%        Relation,
%        " AS table1 ORDER BY random() LIMIT ",
%        Size
%    ], Query),
%    arcpy_util:sql_query_result(Query),
%    designated:relation_key(Relation, IDField),
%    assertz(designated:relation_key(Output, IDField)),
%    % create indices
%    atomics_to_string([
%        "CREATE INDEX ",
%        Output,
%        "_ix_idfield ON ",
%        Output,
%        " USING btree (",
%        IDField,
%        " ASC NULLS LAST)"
%    ], IdIndexQuery),
%    arcpy_util:sql_query_result(IdIndexQuery),
%    atomics_to_string([
%        "CREATE INDEX ",
%        Output,
%        "ix_shape ON ",
%        Output,
%        " USING gist (shape)"
%    ], ShapeIndexQuery),
%    arcpy_util:sql_query_result(ShapeIndexQuery).

%------------------------------------------------------------------------------
% filter_by_relationship(+Input, +Relation, +Attribute, -Output):
%------------------------------------------------------------------------------
% Filetrs Relation according to the IDs in Relationship. Attribute must point to a field in Relationship.

filter_by_relationship(Relation, Relationship, Attribute, Output) :-
    % Check input
    nonvar(Relation),
    nonvar(Relationship),
    var(Output),
    nonvar(Attribute),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    designated:relation_key(Relation, IDField),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " (LIKE ",
        Relation,
        " INCLUDING INDEXES)"
    ], CreateQuery),
    arcpy_util:sql_query_result(CreateQuery),
    atomics_to_string([
        "INSERT INTO ",
        Output,
        " SELECT DISTINCT ON (",
        Relation,
        ".",
        IDField,
        ") ",
        Relation,
        ".* FROM ",
        Relation,
        ", ",
        Relationship,
        " WHERE ",
        Relation,
        ".",
        IDField,
        " = ",
        Relationship,
        ".",
        Attribute
    ], InsertQuery),
    arcpy_util:sql_query_result(InsertQuery),
    designated:relation_key(Relation, IDField),
    assertz(designated:relation_key(Output, IDField)).
%    arcpy_util:uuid(UUID),
%    atomics_to_string(["tmp_", UUID], Output),
%    designated:relation_key(Input, IDField),
%    atomics_to_string([
%        "CREATE TEMP TABLE ",
%        Output,
%        " AS SELECT DISTINCT ON (",
%        Input,
%        ".",
%        IDField,
%        ") ",
%        Input,
%        ".* FROM ",
%        Input,
%        ", ",
%        Relationship,
%        " WHERE ",
%        Input,
%        ".",
%        IDField,
%        " = ",
%        Relationship,
%        ".",
%        Attribute
%    ], Query),
%    arcpy_util:sql_query_result(Query),
%    assertz(designated:relation_key(Output, IDField)),
%    % create indices
%    atomics_to_string([
%        "CREATE INDEX ",
%        Output,
%        "_ix_idfield ON ",
%        Output,
%        " USING btree (",
%        IDField,
%        " ASC NULLS LAST)"
%    ], IdIndexQuery),
%    arcpy_util:sql_query_result(IdIndexQuery),
%    atomics_to_string([
%        "CREATE INDEX ",
%        Output,
%        "ix_shape ON ",
%        Output,
%        " USING gist (shape)"
%    ], ShapeIndexQuery),
%    arcpy_util:sql_query_result(ShapeIndexQuery).

%------------------------------------------------------------------------------
% select_where_query(+Constraint, +Relation, ?Id):
%------------------------------------------------------------------------------
% Is true if Id is the result of the query on Relation with Constraint.

select_where_query(Constraint, Relation, Id) :-
    % Check input
    var(Id),
    % check/get table
    (var(Relation) -> designated:designated_relation(Relation) ; true),
    % Execute query
    designated:relation_key(Relation, IDField),
    atomics_to_string([
        "SELECT ",
        IDField,
        " FROM ",
        Relation,
        " WHERE ",
        Constraint
    ], Query),
    arcpy_util:sql_query_iterator(Query, Result),
    geolog:iterate(Result, [Id]).

select_where_query(Constraint, Relation, Id) :-
    % Check input
    nonvar(Id),
    % check/get table
    (var(Relation) -> designated:designated_relation(Relation) ; true),
    % Execute query
    designated:relation_key(Relation, IDField),
    atomics_to_string([
        "SELECT count(*) FROM ",
        Relation,
        " WHERE ",
        Constraint,
        " and ",
        IDField,
        " = '",
        Id,
        "'"
    ], Query),
    arcpy_util:sql_query_result(Query, Result),
    Result >= 1.

%------------------------------------------------------------------------------
% select_where_query_relational(+Constraint, +Relation, -Output):
%------------------------------------------------------------------------------
% Is true if Output is the relation that contains element of Relation that satisfy Constraint.

select_where_query_relational(Constraint, Relation, Output) :-
    % check/get table
    (var(Relation) -> designated:designated_relation(Relation) ; true),
    % check output variable
    var(Output),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Output),
    atomics_to_string([
        "CREATE TEMP TABLE ",
        Output,
        " (LIKE ",
        Relation,
        " INCLUDING INDEXES)"
    ], CreateQuery),
    arcpy_util:sql_query_result(CreateQuery),
    atomics_to_string([
        "INSERT INTO ",
        Output,
        " SELECT * FROM ",
        Relation,
        " WHERE ",
        Constraint
    ], InsertQuery),
    arcpy_util:sql_query_result(InsertQuery),
    designated:relation_key(Relation, IDField),
    assertz(designated:relation_key(Output, IDField)).

%------------------------------------------------------------------------------
% materialize(+Relation, +FeatureClass):
%------------------------------------------------------------------------------
% Creates a feature class from Relation

materialize(Relation, FeatureClass) :-
    % check/get table
    nonvar(FeatureClass),
    % check output variable
    nonvar(FeatureClass),
    % Execute query
    arcpy_util:uuid(UUID),
    atomics_to_string(["tmp_", UUID], Temp),
    atomics_to_string([
        "CREATE TABLE ",
        Temp,
        " (LIKE ",
        Relation,
        " INCLUDING INDEXES)"
    ], CreateQuery),
    arcpy_util:sql_query_result(CreateQuery),
    atomics_to_string([
        "INSERT INTO ",
        Temp,
        " SELECT * FROM ",
        Relation
    ], InsertQuery),
    arcpy_util:sql_query_result(InsertQuery),
    % Copy table to feature class
    designated:db_connection_path(ConnectionPath),
    atomics_to_string([ConnectionPath, "/", Temp], TempFullPath),
    arcpy_core:arcpy_CopyFeatures_management([TempFullPath, FeatureClass]),
    designated:relation_key(Relation, IDField),
    assertz(designated:relation_key(FeatureClass, IDField)),
    % drop table
    atomics_to_string([
        "DROP TABLE ",
        Temp
    ], DropQuery),
    arcpy_util:sql_query_result(DropQuery).
