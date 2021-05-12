:- module(arcpy_util, [sql_query_result/1, sql_query_result/2, sql_query_iterator/2,
                       extract_selection/2, add_layer/2]).

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Arcpy Util Predicates
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Author: Tobias Grubenmann
	% Email: grubenmann@cs.uni-bonn.de
	% Copyright: (C) 2020 Tobias Grubenmann
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%------------------------------------------------------------------------------
% sql_query_result(+Query)
% sql_query_result(+Query, ?Result)
%------------------------------------------------------------------------------
% Run Query, if database available. 
% Otherwise, just output the query to stdout. 
% The binary version unifies Result to a list of lists. Each inner list 
% represents a successful set of bindings for the variables of Query
% (in the same order as the variables). 

sql_query_result(Query) :-
	designated:db_connection(Connection),
	(  is_dummy_connection(Connection)
	-> write_on_stdout(Query)
	;  arcpy_util:executeArcSDE(Connection, Query)
	).
	
sql_query_result(Query, Result) :- 
	designated:db_connection(Connection),
	(  is_dummy_connection(Connection)
	-> write_on_stdout(Query)
	;  arcpy_util:executeArcSDE(Connection, Query, Result)
	).
	
%------------------------------------------------------------------------------
% sql_query_iterator(+Query, -Iterator)
%------------------------------------------------------------------------------
% Run Query, if database available. 
% Otherwise, just output the query to stdout. 
% Iterator is a newly created Python iterator object. If the database is not
% available, Iterator is a dummy iterator over an empty list. 

sql_query_iterator(Query, Iterator) :- 
	designated:db_connection(Connection),
	(  is_dummy_connection(Connection)
	-> ( write_on_stdout(Query),
	     geolog:iterator([], Iterator)   % external predicate (python) 
	   )
	;  arcpy_util:executeArcSDEIterator(Connection, Query, Iterator)
	).	
	
	
%------------------------------------------------------------------------------
% extract_selection(+Layer, -Selection):
%------------------------------------------------------------------------------
% Creates a new feature class from a layer based on the selection. The
% selection is cleared during the process.

extract_selection(Layer, Selection) :-
    new_in_memory_fc_name(Selection),
    arcpy_core:'arcpy.CopyFeatures_management'([Layer, Selection]),
    arcpy_core:'arcpy.SelectLayerByAttribute_management'([Layer, "CLEAR_SELECTION"]).

%------------------------------------------------------------------------------
% get_single_features(+FeatureClassOrLayer, -Feature):
%------------------------------------------------------------------------------
% Returns all features in a feature class or layer in a non-deterministic
% manner (iterator).

%get_single_features(FeatureClassOrLayer, Feature) :-
%    arcpy_core:'arcpy.Describe'([FeatureClassOrLayer], Description),
%    geolog:get_attribute(Description, "OIDFieldName", FieldName),
%    arcpy_core:'arcpy.da.SearchCursor'([FeatureClassOrLayer, [FieldName]], Cursor),
%    setup_call_cleanup(geolog:call_method(Cursor, "__enter__"),
%                       (
%                           geolog:iterate(Cursor, [Id]),
%                           new_in_memory_fc_name(Feature),
%                           atomics_to_string([FieldName, " = ", Id], FilterExpression),
%                           arcpy_core:'arcpy.Select_analysis'([FeatureClassOrLayer, Feature, FilterExpression])
%                       ),
%                       (
%                           geolog:call_method(Cursor, "__exit__", [none, none, none]),
%                           geolog:delete(Cursor)
%                       )).

%------------------------------------------------------------------------------
% get_single_feature(+FeatureClassOrLayer, +Id, -Feature):
%------------------------------------------------------------------------------
% Returns a single feature which matches ID from a feature class or layer.

%get_single_feature(FeatureClassOrLayer, Id, Feature) :-
%    arcpy_core:'arcpy.Describe'([FeatureClassOrLayer], Description),
%    geolog:get_attribute(Description, "OIDFieldName", FieldName),
%    arcpy_util:new_in_memory_fc_name(Feature),
%    atomics_to_string([FieldName, " = ", Id], FilterExpression),
%    arcpy_core:'arcpy.Select_analysis'([FeatureClassOrLayer, Feature, FilterExpression]).

%------------------------------------------------------------------------------
% new_in_memory_fc_name(-Name):
%------------------------------------------------------------------------------
% Returns a new unique name for an in-memory feature class.

%new_in_memory_fc_name(Name) :-
%    arcpy_core:uuid(UUID),
%    atomics_to_string(["in_memory/fc_", UUID], Name).

%------------------------------------------------------------------------------
% layer_name(?Name, -LayerName)
%------------------------------------------------------------------------------
% Returns Layername that is unique.

%layer_name(Name, LayerName) :-
%    var(Name),
%    arcpy_util:uuid(UUID),
%    atomics_to_string(["layer_", UUID], LayerName).
%
%layer_name(Name, LayerName) :-
%    nonvar(Name),
%    arcpy_core:'arcpy.Exists'([LayerName], Exist),
%    Exist = false,
%    LayerName = Name.
%
%layer_name(Name, LayerName) :-
%    nonvar(Name),
%    arcpy_core:'arcpy.Exists'([LayerName], Exist),
%    Exist = true,
%    arcpy_core:uuid(UUID),
%    atomics_to_string([Name, "_", UUID], LayerName).

%------------------------------------------------------------------------------
% add_layer(+Features, +LayerName):
%------------------------------------------------------------------------------
% Adds the features as a new layer with the name LayerName to the current map.

add_layer(Features, LayerName) :-
    layer_name(LayerName, UniqueLayerName),
    arcpy_core:'arcpy.MakeFeatureLayer_management'([Features, UniqueLayerName]),
    arcpy_core:'arcpy.mapping.Layer'([UniqueLayerName], Layer),
    arcpy_core:'arcpy.mapping.MapDocument'(["CURRENT"], MXD),
    geolog:get_attribute(MXD, "activeDataFrame", DF),
    arcpy_core:'arcpy.mapping.AddLayer'([DF, Layer]).

%------------------------------------------------------------------------------
% feature_layer(?LayerName):
%------------------------------------------------------------------------------
% Returns all known feature layers or true, if LayerName is a feature layer.

%feature_layer(LayerName) :-
%    nonvar(LayerName),
%    arcpy_core:'arcpy.Exists'([LayerName], Exist),
%    Exist = true,
%    arcpy_core:'arcpy.Describe'([LayerName], Description),
%    geolog:get_attribute(Description, "dataType", Type),
%    Type = "FeatureLayer".
%
%feature_layer(LayerName) :-
%    var(LayerName),
%    arcpy_core:'arcpy.mapping.MapDocument'(["CURRENT"], MXD),
%    arcpy_core:'arcpy.mapping.ListLayers'([MXD], Layers),
%    geolog:iterator(Layers, Iterator),
%    geolog:iterate(Iterator, Layer),
%    geolog:get_attribute(Layer, "name", LayerName).

%------------------------------------------------------------------------------
% feature_class(+FeatureClass):
%------------------------------------------------------------------------------
% Returns true if FeatureClass is a feature class.

%feature_class(FeatureClass) :-
%    nonvar(FeatureClass),
%    arcpy_core:'arcpy.Exists'([FeatureClass], Exist),
%    Exist = true,
%    arcpy_core:'arcpy.Describe'([FeatureClass], Description),
%    geolog:get_attribute(Description, "dataType", Type),
%    Type = "FeatureClass".

%------------------------------------------------------------------------------
% feature_class_or_layer(+FeatureClassOrLayer):
%------------------------------------------------------------------------------
% Returns true if FeatureClassOrLayer is a feature class or layer.

%feature_class_or_layer(FeatureClassOrLayer) :-
%    feature_layer(FeatureClassOrLayer).
%
%feature_class_or_layer(FeatureClassOrLayer) :-
%    feature_class(FeatureClassOrLayer).

%------------------------------------------------------------------------------
% single_feature(+FeatureClass):
%------------------------------------------------------------------------------
% Returns true if the feature class contains exactly one feature.

%single_feature(Feature) :-
%    arcpy_core:'arcpy.GetCount_management'([Feature], Counts),
%    geolog:get_by_index(Counts, 0, CountString),
%    number_string(Count, CountString),
%    Count = 1.

%------------------------------------------------------------------------------
% feature_to_geometry(+Feature, -Geometry):
%------------------------------------------------------------------------------
% Returns the geometry of the first feature in a feature class.

%feature_to_geometry(Feature, Geometry) :-
%    arcpy_core:'arcpy.da.SearchCursor'([Feature, ["SHAPE@"]], Cursor),
%    setup_call_cleanup(geolog:call_method(Cursor, "__enter__"),
%                       geolog:next(Cursor, [Geometry]),
%                       (
%                           geolog:call_method(Cursor, "__exit__", [none, none, none]),
%                           geolog:delete(Cursor)
%                       )).

%------------------------------------------------------------------------------
% geometry_to_feature(+Geometry, -Feature):
%------------------------------------------------------------------------------
% Transforms a geometry into a feature class with a single entry.

%geometry_to_feature(Geometry, Feature) :-
%    arcpy_core:uuid(UUID),
%    atomics_to_string(["fc_", UUID], Name),
%    arcpy_core:'arcpy.CreateFeatureclass_management'(["in_memory", Name], Feature),
%    arcpy_core:'arcpy.da.InsertCursor'([Feature, "SHAPE@"], Cursor),
%    setup_call_cleanup(geolog:call_method(Cursor, "__enter__"),
%                       geolog:call_method(Cursor, "insertRow", [[Geometry]]),
%                       (
%                           geolog:call_method(Cursor, "__exit__", [none, none, none]),
%                           geolog:delete(Cursor)
%                       )).

%------------------------------------------------------------------------------
% point_feature(+FeatureClassOrLayer):
%------------------------------------------------------------------------------
% Returns true if FeatureClassOrLayer contains point features.

%point_feature(FeatureClassOrLayer) :-
%    nonvar(FeatureClassOrLayer),
%    arcpy_core:'arcpy.Exists'([FeatureClassOrLayer], Exist),
%    Exist = true,
%    arcpy_core:'arcpy.Describe'([FeatureClassOrLayer], Description),
%    geolog:get_attribute(Description, "shapeType", Type),
%    Type = "Point".

%------------------------------------------------------------------------------
% filter_fc_and_copy(+Input, +Attribute, +Value, -FilteredOutput):
%------------------------------------------------------------------------------
% Filters a feature class according to Value in FieldName and returns a
% filtered copy of the feature class as output.

%filter_fc_and_copy(Input, FieldName, Value, FilteredOutput) :-
%    nonvar(Input),
%    nonvar(FieldName),
%    nonvar(Value),
%    arcpy_util:new_in_memory_fc_name(FilteredOutput),
%    atomics_to_string([FieldName, " = ", Value], FilterExpression),
%    arcpy_core:'arcpy.Select_analysis'([Input, FilteredOutput, FilterExpression]).
%------------------------------------------------------------------------------
% is_dummy_connection(?ConnectionString):
%------------------------------------------------------------------------------
% Indicates the connection string used for dummy connections during testing.

is_dummy_connection('dummy_db_connection').
