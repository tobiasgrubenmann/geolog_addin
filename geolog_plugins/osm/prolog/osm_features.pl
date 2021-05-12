:- module(osm, [entity_type/2, entity_type_relational/3]).

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OSM Features
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Author: Tobias Grubenmann
	% Email: grubenmann@cs.uni-bonn.de
	% Copyright: (C) 2020 Tobias Grubenmann
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%------------------------------------------------------------------------------
% entity_type(?OSMType, ?(Relation, Id)):
%------------------------------------------------------------------------------
% Is true if (Relation, Id) is of type OSMType.

entity_type(OSMType, (Relation, Id)) :-
    % get where-clause / feature-type
    osm_constraint(OSMType, Constraint),
    % execute query
    postgres:select_where_query(Constraint, Relation, Id) .

%------------------------------------------------------------------------------
% entity_type_relational(?OSMType, ?Relation, -Output) :
%------------------------------------------------------------------------------
% Is true if Output contains all features in Input that are of type FeatureType.

entity_type_relational(OSMType, Relation, Output) :-
    % get where-clause / feature-type
    osm_constraint(OSMType, Constraint),
    % execute query
    postgres:select_where_query_relational(Constraint, Relation, Output).

%------------------------------------------------------------------------------
% osm_constraint(?FeatureType, ?WhereClause):
%------------------------------------------------------------------------------
% Matches feature types with the corresponding where clause.

osm_constraint(public_features, "code >= 2000 and code <= 2099").

osm_constraint(education_features, "code >= 2080 and code <= 2089").

osm_constraint(school_features, "code = 2082").

osm_constraint(health_features, "code >= 2100 and code <= 2199").

osm_constraint(leisure_features, "code >= 2200 and code <= 2299").

osm_constraint(sports_features, "code >= 2250 and code <= 2259").

osm_constraint(catering_features, "code >= 2300 and code <= 2399").

osm_constraint(accommodation_features, "code >= 2400 and code <= 2499").

osm_constraint(accommodation_outdoor_features, "code >= 2420 and code <= 2429").

osm_constraint(shopping_features, "code >= 2500 and code <= 2599").

osm_constraint(money_features, "code >= 2600 and code <= 2699").

osm_constraint(tourism_features, "code >= 2700 and code <= 2799").

osm_constraint(tourism_destination_features, "code >= 2720 and code <= 2749").

osm_constraint(misc_poi_features, "code >= 2900 and code <= 2999").

osm_constraint(traffic_features, "code >= 5200 and code <= 5299").

osm_constraint(traffic_street_features, "code >= 5200 and code <= 5209").

osm_constraint(traffic_signal_features, "code = 5201").

osm_constraint(crossing_features, "code = 5204").

osm_constraint(fuel_parking_features, "code >= 5250 and code <= 5279").

osm_constraint(traffic_water_features, "code >= 5300 and code <= 5399").

osm_constraint(transport_infrastructure_features, "code >= 5600 and code <= 5699").

osm_constraint(road_features, "code >= 5100 and code <= 5199").

osm_constraint(major_road_features, "code >= 5110 and code <= 5119").

osm_constraint(minor_road_features, "code >= 5120 and code <= 5129").

osm_constraint(highway_link_features, "code >= 5130 and code <= 5139").

osm_constraint(small_road_features, "code >= 5140 and code <= 5149").

osm_constraint(path_features, "code >= 5150 and code <= 5159").

osm_constraint(unknown_road_features, "code = 5199").

osm_constraint(railway_features, "code = 5601").

osm_constraint(railway_halt_features, "code = 5602").

osm_constraint(tram_stop_features, "code = 5603").

osm_constraint(bus_stop_features, "code = 5621").

osm_constraint(bus_station, "code = 5622").

osm_constraint(taxi_rank, "code = 5641").