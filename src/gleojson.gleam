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

import gleam/dynamic
import gleam/json

// import gleam/list
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
pub type Feature(properties) {
  Feature(
    geometry: option.Option(Geometry),
    properties: option.Option(properties),
    id: option.Option(FeatureId),
  )
}

/// A collection of features in a GeoJSON object.
pub type FeatureCollection(properties) {
  FeatureCollection(features: List(Feature(properties)))
}

/// A GeoJSON object.
pub type GeoJSON(properties) {
  GeoJSONGeometry(Geometry)
  GeoJSONFeature(Feature(properties))
  GeoJSONFeatureCollection(FeatureCollection(properties))
}

// Encoding Functions

/// Encodes a geometry into a JSON object.
fn encode_geometry(geometry: Geometry) -> json.Json {
  case geometry {
    Point(coordinates) ->
      json.object([
        #("type", json.string("Point")),
        #("coordinates", json.array(coordinates, of: json.float)),
      ])
    MultiPoint(multipoint) ->
      json.object([
        #("type", json.string("MultiPoint")),
        #(
          "coordinates",
          json.array(multipoint, of: json.array(_, of: json.float)),
        ),
      ])
    LineString(linestring) ->
      json.object([
        #("type", json.string("LineString")),
        #(
          "coordinates",
          json.array(linestring, of: json.array(_, of: json.float)),
        ),
      ])
    MultiLineString(multilinestring) ->
      json.object([
        #("type", json.string("MultiLineString")),
        #(
          "coordinates",
          json.array(multilinestring, of: json.array(_, of: json.array(
            _,
            of: json.float,
          ))),
        ),
      ])
    Polygon(polygon) ->
      json.object([
        #("type", json.string("Polygon")),
        #(
          "coordinates",
          json.array(polygon, of: json.array(_, of: json.array(
            _,
            of: json.float,
          ))),
        ),
      ])
    MultiPolygon(multipolygon) ->
      json.object([
        #("type", json.string("MultiPolygon")),
        #(
          "coordinates",
          json.array(
            multipolygon,
            of: json.array(_, of: json.array(_, of: json.array(
              _,
              of: json.float,
            ))),
          ),
        ),
      ])
    GeometryCollection(collection) ->
      json.object([
        #("type", json.string("GeometryCollection")),
        #("geometries", json.array(collection, of: encode_geometry)),
      ])
  }
}

/// Encodes a feature into a JSON object.
fn encode_feature(
  properties_encoder: fn(properties) -> json.Json,
  feature: Feature(properties),
) -> json.Json {
  let Feature(geometry_opt, properties_opt, id_opt) = feature
  let geometry_json = case geometry_opt {
    option.Some(geometry) -> encode_geometry(geometry)
    option.None -> json.null()
  }
  let properties_json = case properties_opt {
    option.Some(props) -> properties_encoder(props)
    option.None -> json.null()
  }

  let base_obj = [
    #("type", json.string("Feature")),
    #("geometry", geometry_json),
    #("properties", properties_json),
  ]
  let full_obj = case id_opt {
    option.Some(StringId(id)) -> [#("id", json.string(id)), ..base_obj]
    option.Some(NumberId(id)) -> [#("id", json.float(id)), ..base_obj]
    option.None -> base_obj
  }
  json.object(full_obj)
}

/// Encodes a feature collection into a JSON object.
fn encode_featurecollection(
  properties_encoder: fn(properties) -> json.Json,
  collection: FeatureCollection(properties),
) -> json.Json {
  let FeatureCollection(features) = collection
  json.object([
    #("type", json.string("FeatureCollection")),
    #(
      "features",
      json.array(features, of: fn(feature) {
        encode_feature(properties_encoder, feature)
      }),
    ),
  ])
}

/// Encodes a GeoJSON object into a JSON value.
///
/// ## Example
///
/// ```gleam
/// let point = GeoJSONGeometry(Point([0.0, 0.0]))
/// let encoded = encode_geojson(point, properties_encoder)
/// // encoded will be a JSON representation of the GeoJSON object
/// ```
pub fn encode_geojson(
  geojson: GeoJSON(properties),
  properties_encoder: fn(properties) -> json.Json,
) -> json.Json {
  case geojson {
    GeoJSONGeometry(geometry) -> encode_geometry(geometry)
    GeoJSONFeature(feature) -> encode_feature(properties_encoder, feature)
    GeoJSONFeatureCollection(collection) ->
      encode_featurecollection(properties_encoder, collection)
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

fn decode_type_field(
  dyn_value: dynamic.Dynamic,
) -> Result(String, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dyn_value)
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
  properties_decoder: dynamic.Decoder(properties),
  dyn_value: dynamic.Dynamic,
) -> Result(Feature(properties), List(dynamic.DecodeError)) {
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
          of: dynamic.optional(properties_decoder),
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
  properties_decoder: dynamic.Decoder(properties),
  dyn_value: dynamic.Dynamic,
) -> Result(FeatureCollection(properties), List(dynamic.DecodeError)) {
  use type_str <- result.try(decode_type_field(dyn_value))
  case type_str {
    "FeatureCollection" ->
      dynamic.field(
        named: "features",
        of: dynamic.list(of: fn(dyn_value) {
          feature_decoder(properties_decoder, dyn_value)
        }),
      )(dyn_value)
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
///   |> result.then(fn dyn_value { geojson_decoder(properties_decoder, dyn_value) })
/// // decoded will be Ok(GeoJSONGeometry(Point([0.0, 0.0]))) if successful
/// ```
///
/// Note: This function expects a valid GeoJSON structure. Invalid or incomplete
/// GeoJSON data will result in a decode error.
pub fn geojson_decoder(
  properties_decoder: dynamic.Decoder(properties),
  dyn_value: dynamic.Dynamic,
) -> Result(GeoJSON(properties), List(dynamic.DecodeError)) {
  use type_str <- result.try(decode_type_field(dyn_value))
  case type_str {
    "Feature" ->
      result.map(feature_decoder(properties_decoder, dyn_value), GeoJSONFeature)
    "FeatureCollection" ->
      result.map(
        featurecollection_decoder(properties_decoder, dyn_value),
        GeoJSONFeatureCollection,
      )
    _ -> result.map(geometry_decoder(dyn_value), GeoJSONGeometry)
  }
}
