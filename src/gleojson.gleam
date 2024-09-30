//// Functions for working with GeoJSON data.
////
//// This module provides types and functions for encoding and decoding GeoJSON data.
//// It supports all GeoJSON object types including Point, MultiPoint, LineString,
//// MultiLineString, Polygon, MultiPolygon, GeometryCollection, Feature, and FeatureCollection.
////
//// ## Usage
////
//// To use this module, you can import it in your Gleam code:
////
//// ```gleam
//// import gleojson
//// ```
////
//// Then you can use the provided functions to encode and decode GeoJSON data.

import gleam/dict
import gleam/dynamic
import gleam/list
import gleam/option
import gleam/result

/// A position in a GeoJSON object.
pub type Position =
  List(Float)

/// A Geometry in a GeoJSON object.
pub type Geometry {
  Point(coordinates: Position)
  MultiPoint(coordinates: List(Position))
  LineString(coordinates: List(Position))
  MultiLineString(coordinates: List(List(Position)))
  Polygon(coordinates: List(List(Position)))
  MultiPolygon(coordinates: List(List(List(Position))))
  GeometryCollection(geometries: List(Geometry))
}

/// Represents either a String or a Number, used for the Feature id.
pub type FeatureId {
  StringId(String)
  NumberId(Float)
}

/// A feature in a GeoJSON object, consisting of a geometry, properties, and an optional id.
pub type Feature {
  Feature(
    geometry: option.Option(Geometry),
    properties: option.Option(dict.Dict(String, dynamic.Dynamic)),
    id: option.Option(FeatureId),
  )
}

/// A collection of features in a GeoJSON object.
pub type FeatureCollection {
  FeatureCollection(features: List(Feature))
}

/// A GeoJSON object.
pub type GeoJSON {
  GeoJSONGeometry(Geometry)
  GeoJSONFeature(Feature)
  GeoJSONFeatureCollection(FeatureCollection)
}

// Encoding Functions

/// Encodes a geometry into a dynamic value.
fn encode_geometry(geometry: Geometry) -> dynamic.Dynamic {
  case geometry {
    Point(coordinates) -> {
      dict.from_list([
        #("type", dynamic.from("Point")),
        #("coordinates", dynamic.from(coordinates)),
      ])
    }
    MultiPoint(multipoint) -> {
      dict.from_list([
        #("type", dynamic.from("MultiPoint")),
        #("coordinates", dynamic.from(multipoint)),
      ])
    }
    LineString(linestring) -> {
      dict.from_list([
        #("type", dynamic.from("LineString")),
        #("coordinates", dynamic.from(linestring)),
      ])
    }
    MultiLineString(multilinestring) -> {
      dict.from_list([
        #("type", dynamic.from("MultiLineString")),
        #("coordinates", dynamic.from(multilinestring)),
      ])
    }
    Polygon(polygon) -> {
      dict.from_list([
        #("type", dynamic.from("Polygon")),
        #("coordinates", dynamic.from(polygon)),
      ])
    }
    MultiPolygon(multipolygon) -> {
      dict.from_list([
        #("type", dynamic.from("MultiPolygon")),
        #("coordinates", dynamic.from(multipolygon)),
      ])
    }
    GeometryCollection(collection) -> {
      let geometries_dyn_list = list.map(collection, encode_geometry)
      dict.from_list([
        #("type", dynamic.from("GeometryCollection")),
        #("geometries", dynamic.from(geometries_dyn_list)),
      ])
    }
  }
  |> dynamic.from
}

/// Encodes a feature into a dynamic value.
fn encode_feature(feature: Feature) -> dynamic.Dynamic {
  let Feature(geometry_opt, properties_opt, id_opt) = feature
  let geometry_dyn = case geometry_opt {
    option.Some(geometry) -> encode_geometry(geometry)
    option.None -> dynamic.from(Nil)
  }
  let properties_dyn = case properties_opt {
    option.Some(props) -> dynamic.from(props)
    option.None -> dynamic.from(Nil)
  }
  let base_obj =
    dict.from_list([
      #("type", dynamic.from("Feature")),
      #("geometry", geometry_dyn),
      #("properties", properties_dyn),
    ])
  case id_opt {
    option.Some(StringId(id)) -> dict.insert(base_obj, "id", dynamic.from(id))
    option.Some(NumberId(id)) -> dict.insert(base_obj, "id", dynamic.from(id))
    option.None -> base_obj
  }
  |> dynamic.from
}

/// Encodes a feature collection into a dynamic value.
fn encode_featurecollection(collection: FeatureCollection) -> dynamic.Dynamic {
  let FeatureCollection(features) = collection
  let features_dyn_list = list.map(features, encode_feature)
  dict.from_list([
    #("type", dynamic.from("FeatureCollection")),
    #("features", dynamic.from(features_dyn_list)),
  ])
  |> dynamic.from
}

/// Encodes a GeoJSON object into a dynamic value.
///
/// ## Example
///
/// ```gleam
/// let point = GeoJSONGeometry(Point([0.0, 0.0]))
/// let encoded = encode_geojson(point)
/// // encoded will be a dynamic representation of the GeoJSON object
/// ```
pub fn encode_geojson(geojson: GeoJSON) -> dynamic.Dynamic {
  case geojson {
    GeoJSONGeometry(geometry) -> encode_geometry(geometry)
    GeoJSONFeature(feature) -> encode_feature(feature)
    GeoJSONFeatureCollection(collection) -> encode_featurecollection(collection)
  }
}

// Decoding Functions

/// Decodes a position from a dynamic value.
fn position_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(Position, List(dynamic.DecodeError)) {
  dynamic.list(of: dynamic.float)(dyn_value)
}

/// Decodes a list of positions from a dynamic value.
fn positions_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(List(Position), List(dynamic.DecodeError)) {
  dynamic.list(of: position_decoder)(dyn_value)
}

/// Decodes a list of lists of positions from a dynamic value.
fn positions_list_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(List(List(Position)), List(dynamic.DecodeError)) {
  dynamic.list(of: positions_decoder)(dyn_value)
}

/// Decodes a list of lists of lists of positions from a dynamic value.
fn positions_list_list_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(List(List(List(Position))), List(dynamic.DecodeError)) {
  dynamic.list(of: positions_list_decoder)(dyn_value)
}

/// Decodes a geometry from a dynamic value.
fn geometry_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(Geometry, List(dynamic.DecodeError)) {
  use type_str <- result.try(decode_type_field(dyn_value))
  case type_str {
    "Point" ->
      dynamic.field(named: "coordinates", of: position_decoder)(dyn_value)
      |> result.map(Point)
    "MultiPoint" ->
      dynamic.field(named: "coordinates", of: positions_decoder)(dyn_value)
      |> result.map(MultiPoint)
    "LineString" ->
      dynamic.field(named: "coordinates", of: positions_decoder)(dyn_value)
      |> result.map(LineString)
    "MultiLineString" ->
      dynamic.field(named: "coordinates", of: positions_list_decoder)(dyn_value)
      |> result.map(MultiLineString)
    "Polygon" ->
      dynamic.field(named: "coordinates", of: positions_list_decoder)(dyn_value)
      |> result.map(Polygon)
    "MultiPolygon" ->
      dynamic.field(named: "coordinates", of: positions_list_list_decoder)(
        dyn_value,
      )
      |> result.map(MultiPolygon)
    "GeometryCollection" ->
      dynamic.field(named: "geometries", of: dynamic.list(of: geometry_decoder))(
        dyn_value,
      )
      |> result.map(GeometryCollection)
    _ ->
      Error([
        dynamic.DecodeError(
          expected: "Known Geometry Type",
          found: type_str,
          path: ["type"],
        ),
      ])
  }
}

/// Decodes a FeatureId from a dynamic value.
fn feature_id_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(FeatureId, List(dynamic.DecodeError)) {
  dynamic.string(dyn_value)
  |> result.map(StringId)
  |> result.lazy_or(fn() { dynamic.float(dyn_value) |> result.map(NumberId) })
}

/// Decodes a feature from a dynamic value.
fn feature_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(Feature, List(dynamic.DecodeError)) {
  use type_str <- result.try(decode_type_field(dyn_value))
  case type_str {
    "Feature" -> {
      let geometry_result =
        dynamic.field(named: "geometry", of: dynamic.optional(geometry_decoder))(
          dyn_value,
        )

      let properties_result =
        dynamic.field(
          named: "properties",
          of: dynamic.optional(dynamic.dict(dynamic.string, dynamic.dynamic)),
        )(dyn_value)
        |> result.map_error(fn(_errs) {
          [
            dynamic.DecodeError(expected: "Properties", found: "Invalid", path: [
              "properties",
            ]),
          ]
        })

      let id_result =
        dynamic.optional_field(named: "id", of: feature_id_decoder)(dyn_value)
        |> result.map_error(fn(_errs) {
          [dynamic.DecodeError(expected: "ID", found: "Invalid", path: ["id"])]
        })

      let geometry_result =
        geometry_result
        |> result.map_error(fn(_errs) {
          [
            dynamic.DecodeError(expected: "Geometry", found: "Invalid", path: [
              "geometry",
            ]),
          ]
        })

      use geometry_opt <- result.try(geometry_result)
      use properties_opt <- result.try(properties_result)
      use id_opt <- result.try(id_result)
      Ok(Feature(geometry_opt, properties_opt, id_opt))
    }

    _ ->
      Error([
        dynamic.DecodeError(expected: "Feature", found: type_str, path: ["type"]),
      ])
  }
}

/// Decodes a feature collection from a dynamic value.
fn featurecollection_decoder(
  dyn_value,
) -> Result(FeatureCollection, List(dynamic.DecodeError)) {
  use type_str <- result.try(decode_type_field(dyn_value))
  case type_str {
    "FeatureCollection" ->
      dynamic.field(named: "features", of: dynamic.list(of: feature_decoder))(
        dyn_value,
      )
      |> result.map(FeatureCollection)
    _ ->
      Error([
        dynamic.DecodeError(
          expected: "FeatureCollection",
          found: type_str,
          path: ["type"],
        ),
      ])
  }
}

/// Decodes a GeoJSON object from a dynamic value.
///
/// ## Example
///
/// ```gleam
/// let json_string = "{\"type\":\"Point\",\"coordinates\":[0.0,0.0]}"
/// let decoded = json.decode(json_string)
///   |> result.then(geojson_decoder)
/// // decoded will be Ok(GeoJSONGeometry(Point([0.0, 0.0]))) if successful
/// ```
///
/// Note: This function expects a valid GeoJSON structure. Invalid or incomplete
/// GeoJSON data will result in a decode error.
pub fn geojson_decoder(dyn_value) -> Result(GeoJSON, List(dynamic.DecodeError)) {
  use type_str <- result.try(decode_type_field(dyn_value))
  case type_str {
    "Feature" -> result.map(feature_decoder(dyn_value), GeoJSONFeature)
    "FeatureCollection" ->
      result.map(featurecollection_decoder(dyn_value), GeoJSONFeatureCollection)
    _ -> result.map(geometry_decoder(dyn_value), GeoJSONGeometry)
  }
}

fn decode_type_field(dyn_value) -> Result(String, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dyn_value)
}
