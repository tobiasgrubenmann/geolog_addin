:- module(designated, []).

:- multifile relation_key/2.
:- dynamic relation_key/2.

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Designated
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Author: Tobias Grubenmann
	% Email: grubenmann@cs.uni-bonn.de
	% Copyright: (C) 2020 Tobias Grubenmann
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% initialize_db_connection(+ConnectionFile, ?Mode)
%
% If ConnectionFile exists, open connection to database and 
% unify Mode with 'run', else store dummy connection ID and 
% unify Mode with 'dummy_db_connection'. 
initialize_db_connection(ConnectionFile, Mode) :-
    retractall(db_connection(_)),
    ( exists_file(ConnectionFile)
	-> ( arcpy_core:'arcpy.ArcSDESQLExecute'([ConnectionFile], Connection),
	     asserta(db_connection(Connection)),
	     Mode = run
	   )
	;  ( asserta(db_connection('dummy_db_connection')),
	     Mode = 'dummy_db_connection'
	   )
	),
    asserta(db_connection_path(ConnectionFile)).

%%------------------------------------------------------------------------------
%% desginated_feature_layer(?LayerName):
%%------------------------------------------------------------------------------
%
%designated_feature_layer(LayerName) :-
%    designated_relation(LayerName),
%    arcpy_util:feature_layer(LayerName).
%
%%------------------------------------------------------------------------------
%% designated_feature_class(?FeatureClass):
%%------------------------------------------------------------------------------
%
%designated_feature_class(FeatureClass) :-
%    designated_relation(FeatureClass),
%    arcpy_util:feature_class(FeatureClass).
%
%designated_feature_class(FeatureClass) :-
%    designated_relation(FeatureLayer),
%    arcpy_util:feature_layer(FeatureLayer),
%    arcpy_core:'arcpy.Describe'([FeatureLayer], Description),
%    geolog:get_attribute(Description, "featureClass", FeatureClassDescription),
%    geolog:get_attribute(FeatureClassDescription, "name", FeatureClass).
%
%%------------------------------------------------------------------------------
%% designated_single_feature(?FeatureClass):
%%------------------------------------------------------------------------------
%
%designated_feature(FeatureClass) :-
%    designated_relation(FeatureClass),
%    arcpy_util:single_feature(FeatureClass).
%
%%------------------------------------------------------------------------------
%% designate_name(+Name):
%%------------------------------------------------------------------------------
%
%designate_name(Name) :-
%    assertz(designated_relation(Name)).
