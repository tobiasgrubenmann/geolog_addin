% ----------------------------------------------------------------------------------
% Start of system by consulting just this file and calling start_geolog/1
% (without manually consulting files from the other geolog plugins).
% ----------------------------------------------------------------------------------
%
% Alternative use options:
%   0. Consult this file automatically, when geolog starts.
%   1. Application invokes start_geolog(DBCOnnectionFile).
% OR
%   0. Application provides db_connection_file_path(DBCOnnectionFile). fact.
%   1. Consult this file automatically, when geolog starts.
%      This file contains call 
%          to db_connection_file_path(DBCOnnectionFile),
%          start_geolog(DBCOnnectionFile),
%          ... error handling ... 
% ----------------------------------------------------------------------------------

:- module( geologstart, 
         [ start_geolog/1  % (+FullPathOfDBConnectionFile)
         ]
         ).

% Update the following fact in the load file of the respective plugin
% if the folder structure of any plugin changes
geolog_plugin_suffix( geolog_main,     'geolog_main/geolog_plugins/arcpy_processes/prolog/start.pl').
geolog_plugin_suffix( geolog_osm,      'geolog_osm/geolog_plugins/osm/prolog/osm_features.pl').
geolog_plugin_suffix( geolog_postgres, 'geolog_postgres/geolog_plugins/postgres/prolog/load.pl').


load_geolog :-
	% Determine path of this file
    clause(load_geolog,_,Ref),
    clause_property(Ref,file(EntryPointFileMain)),
	
	% Suffix of known Prolog entry point files
	geolog_plugin_suffix( geolog_main,     SuffixMain),
	geolog_plugin_suffix( geolog_osm,      SuffixOSM),
	geolog_plugin_suffix( geolog_postgres, SuffixPostgres),
	
	atom_concat(Root, SuffixMain, EntryPointFileMain),
	escape_path(Root,EscapedRoot),
	
    % Determine path of the other entry point files 
	% by adding the respecitve suffix
	atom_concat(EscapedRoot, SuffixOSM,      EntryPointFileOSM),
	atom_concat(EscapedRoot, SuffixPostgres, EntryPointFilePostgres),	

    % Consult all entry points
	consult(EntryPointFileMain),
	consult(EntryPointFileOSM),
	consult(EntryPointFilePostgres).

escape_path(Root,Root). % TODO: Dummy
	
start_geolog(DBConnectionFile) :-
	load_geolog,
	designated:initialize_db_connection(DBConnectionFile, _).


