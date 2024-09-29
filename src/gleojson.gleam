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
//// Types

import gleam/dict
import gleam/dynamic
import gleam/list
import gleam/option
import gleam/result

/// A position in a GeoJSON object.
pub type Position =
  List(Float)

/// A point in a GeoJSON object.
pub type Point {
  Point(coordinates: Position)
}

/// A multi-point in a GeoJSON object.
pub type MultiPoint {
  MultiPoint(coordinates: List(Position))
}

/// A line string in a GeoJSON object.
pub type LineString {
  LineString(coordinates: List(Position))
}

/// A multi-line string in a GeoJSON object.
pub type MultiLineString {
  MultiLineString(coordinates: List(List(Position)))
}

/// A polygon in a GeoJSON object.
pub type Polygon {
  Polygon(coordinates: List(List(Position)))
}

/// A multi-polygon in a GeoJSON object.
pub type MultiPolygon {
  MultiPolygon(coordinates: List(List(List(Position))))
}

/// A collection of geometries in a GeoJSON object.
pub type GeometryCollection {
  GeometryCollection(geometries: List(Geometry))
}

/// A geometry in a GeoJSON object.
pub type Geometry {
  GeometryPoint(Point)
  GeometryMultiPoint(MultiPoint)
  GeometryLineString(LineString)
  GeometryMultiLineString(MultiLineString)
  GeometryPolygon(Polygon)
  GeometryMultiPolygon(MultiPolygon)
  GeometryGeometryCollection(GeometryCollection)
}

/// A feature in a GeoJSON object.
pub type Feature {
  Feature(
    geometry: option.Option(Geometry),
    properties: option.Option(dict.Dict(String, dynamic.Dynamic)),
    id: option.Option(dynamic.Dynamic),
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

/// Encodes a position into a dynamic value.
pub fn encode_position(position: Position) -> dynamic.Dynamic {
  dynamic.from(position)
}

/// Encodes a list of positions into a dynamic value.
pub fn encode_positions(positions: List(Position)) -> dynamic.Dynamic {
  dynamic.from(positions)
}

/// Encodes a list of positions into a dynamic value.
pub fn encode_positions_list(
  positions_list: List(List(Position)),
) -> dynamic.Dynamic {
  dynamic.from(positions_list)
}

/// Encodes a list of lists of positions into a dynamic value.
pub fn encode_positions_list_list(
  positions_list_list: List(List(List(Position))),
) -> dynamic.Dynamic {
  dynamic.from(positions_list_list)
}

/// Encodes a point into a dynamic value.
pub fn encode_point(point: Point) -> dynamic.Dynamic {
  let Point(coordinates) = point
  let obj =
    dict.from_list([
      #("type", dynamic.from("Point")),
      #("coordinates", encode_position(coordinates)),
    ])
  dynamic.from(obj)
}

/// Encodes a multi-point into a dynamic value.
pub fn encode_multipoint(multipoint: MultiPoint) -> dynamic.Dynamic {
  let MultiPoint(coordinates) = multipoint
  let obj =
    dict.from_list([
      #("type", dynamic.from("MultiPoint")),
      #("coordinates", encode_positions(coordinates)),
    ])
  dynamic.from(obj)
}

/// Encodes a line string into a dynamic value.
pub fn encode_linestring(linestring: LineString) -> dynamic.Dynamic {
  let LineString(coordinates) = linestring
  let obj =
    dict.from_list([
      #("type", dynamic.from("LineString")),
      #("coordinates", encode_positions(coordinates)),
    ])
  dynamic.from(obj)
}

/// Encodes a multi-line string into a dynamic value.
pub fn encode_multilinestring(
  multilinestring: MultiLineString,
) -> dynamic.Dynamic {
  let MultiLineString(coordinates) = multilinestring
  let obj =
    dict.from_list([
      #("type", dynamic.from("MultiLineString")),
      #("coordinates", encode_positions_list(coordinates)),
    ])
  dynamic.from(obj)
}

/// Encodes a polygon into a dynamic value.
pub fn encode_polygon(polygon: Polygon) -> dynamic.Dynamic {
  let Polygon(coordinates) = polygon
  let obj =
    dict.from_list([
      #("type", dynamic.from("Polygon")),
      #("coordinates", encode_positions_list(coordinates)),
    ])
  dynamic.from(obj)
}

/// Encodes a multi-polygon into a dynamic value.
pub fn encode_multipolygon(multipolygon: MultiPolygon) -> dynamic.Dynamic {
  let MultiPolygon(coordinates) = multipolygon
  let obj =
    dict.from_list([
      #("type", dynamic.from("MultiPolygon")),
      #("coordinates", encode_positions_list_list(coordinates)),
    ])
  dynamic.from(obj)
}

/// Encodes a geometry collection into a dynamic value.
pub fn encode_geometrycollection(
  collection: GeometryCollection,
) -> dynamic.Dynamic {
  let GeometryCollection(geometries) = collection
  let geometries_dyn_list = list.map(geometries, encode_geometry)
  let obj =
    dict.from_list([
      #("type", dynamic.from("GeometryCollection")),
      #("geometries", dynamic.from(geometries_dyn_list)),
    ])
  dynamic.from(obj)
}

/// Encodes a geometry into a dynamic value.
pub fn encode_geometry(geometry: Geometry) -> dynamic.Dynamic {
  case geometry {
    GeometryPoint(point) -> encode_point(point)
    GeometryMultiPoint(multipoint) -> encode_multipoint(multipoint)
    GeometryLineString(linestring) -> encode_linestring(linestring)
    GeometryMultiLineString(multilinestring) ->
      encode_multilinestring(multilinestring)
    GeometryPolygon(polygon) -> encode_polygon(polygon)
    GeometryMultiPolygon(multipolygon) -> encode_multipolygon(multipolygon)
    GeometryGeometryCollection(collection) ->
      encode_geometrycollection(collection)
  }
}

/// Encodes a feature into a dynamic value.
pub fn encode_feature(feature: Feature) -> dynamic.Dynamic {
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
  let obj = case id_opt {
    option.Some(id_dyn) -> dict.insert(base_obj, "id", id_dyn)
    option.None -> base_obj
  }
  dynamic.from(obj)
}

/// Encodes a feature collection into a dynamic value.
pub fn encode_featurecollection(
  collection: FeatureCollection,
) -> dynamic.Dynamic {
  let FeatureCollection(features) = collection
  let features_dyn_list = list.map(features, encode_feature)
  let obj =
    dict.from_list([
      #("type", dynamic.from("FeatureCollection")),
      #("features", dynamic.from(features_dyn_list)),
    ])
  dynamic.from(obj)
}

/// Encodes a GeoJSON object into a dynamic value.
pub fn encode_geojson(geojson: GeoJSON) -> dynamic.Dynamic {
  case geojson {
    GeoJSONGeometry(geometry) -> encode_geometry(geometry)
    GeoJSONFeature(feature) -> encode_feature(feature)
    GeoJSONFeatureCollection(collection) -> encode_featurecollection(collection)
  }
}

// Decoding Functions

/// Decodes a position from a dynamic value.
pub fn position_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(Position, List(dynamic.DecodeError)) {
  dynamic.list(of: dynamic.float)(dynamic_value)
}

/// Decodes a list of positions from a dynamic value.
pub fn positions_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(List(Position), List(dynamic.DecodeError)) {
  dynamic.list(of: position_decoder)(dynamic_value)
}

/// Decodes a list of lists of positions from a dynamic value.
pub fn positions_list_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(List(List(Position)), List(dynamic.DecodeError)) {
  dynamic.list(of: positions_decoder)(dynamic_value)
}

/// Decodes a list of lists of lists of positions from a dynamic value.
pub fn positions_list_list_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(List(List(List(Position))), List(dynamic.DecodeError)) {
  dynamic.list(of: positions_list_decoder)(dynamic_value)
}

/// Decodes a point from a dynamic value.
pub fn point_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(Point, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "Point" ->
        dynamic.field(named: "coordinates", of: position_decoder)(dynamic_value)
        |> result.map(Point)
      _ ->
        Error([
          dynamic.DecodeError(expected: "Point", found: type_str, path: ["type"]),
        ])
    }
  })
}

/// Decodes a multi-point from a dynamic value.
pub fn multipoint_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(MultiPoint, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "MultiPoint" ->
        dynamic.field(named: "coordinates", of: positions_decoder)(
          dynamic_value,
        )
        |> result.map(MultiPoint)
      _ ->
        Error([
          dynamic.DecodeError(expected: "MultiPoint", found: type_str, path: [
            "type",
          ]),
        ])
    }
  })
}

/// Decodes a line string from a dynamic value.
pub fn linestring_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(LineString, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "LineString" ->
        dynamic.field(named: "coordinates", of: positions_decoder)(
          dynamic_value,
        )
        |> result.map(LineString)
      _ ->
        Error([
          dynamic.DecodeError(expected: "LineString", found: type_str, path: [
            "type",
          ]),
        ])
    }
  })
}

/// Decodes a multi-line string from a dynamic value.
pub fn multilinestring_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(MultiLineString, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "MultiLineString" ->
        dynamic.field(named: "coordinates", of: positions_list_decoder)(
          dynamic_value,
        )
        |> result.map(MultiLineString)
      _ ->
        Error([
          dynamic.DecodeError(
            expected: "MultiLineString",
            found: type_str,
            path: ["type"],
          ),
        ])
    }
  })
}

/// Decodes a polygon from a dynamic value.
pub fn polygon_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(Polygon, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "Polygon" ->
        dynamic.field(named: "coordinates", of: positions_list_decoder)(
          dynamic_value,
        )
        |> result.map(Polygon)
      _ ->
        Error([
          dynamic.DecodeError(expected: "Polygon", found: type_str, path: [
            "type",
          ]),
        ])
    }
  })
}

/// Decodes a multi-polygon from a dynamic value.
pub fn multipolygon_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(MultiPolygon, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "MultiPolygon" ->
        dynamic.field(named: "coordinates", of: positions_list_list_decoder)(
          dynamic_value,
        )
        |> result.map(MultiPolygon)
      _ ->
        Error([
          dynamic.DecodeError(expected: "MultiPolygon", found: type_str, path: [
            "type",
          ]),
        ])
    }
  })
}

/// Decodes a geometry collection from a dynamic value.
pub fn geometrycollection_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(GeometryCollection, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "GeometryCollection" ->
        dynamic.field(
          named: "geometries",
          of: dynamic.list(of: geometry_decoder),
        )(dynamic_value)
        |> result.map(GeometryCollection)
      _ ->
        Error([
          dynamic.DecodeError(
            expected: "GeometryCollection",
            found: type_str,
            path: ["type"],
          ),
        ])
    }
  })
}

/// Decodes a geometry from a dynamic value.
pub fn geometry_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(Geometry, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "Point" ->
        point_decoder(dynamic_value)
        |> result.map(GeometryPoint)
      "MultiPoint" ->
        multipoint_decoder(dynamic_value)
        |> result.map(GeometryMultiPoint)
      "LineString" ->
        linestring_decoder(dynamic_value)
        |> result.map(GeometryLineString)
      "MultiLineString" ->
        multilinestring_decoder(dynamic_value)
        |> result.map(GeometryMultiLineString)
      "Polygon" ->
        polygon_decoder(dynamic_value)
        |> result.map(GeometryPolygon)
      "MultiPolygon" ->
        multipolygon_decoder(dynamic_value)
        |> result.map(GeometryMultiPolygon)
      "GeometryCollection" ->
        geometrycollection_decoder(dynamic_value)
        |> result.map(GeometryGeometryCollection)
      _ ->
        Error([
          dynamic.DecodeError(
            expected: "Known Geometry Type",
            found: type_str,
            path: ["type"],
          ),
        ])
    }
  })
}

/// Decodes a feature from a dynamic value.
pub fn feature_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(Feature, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "Feature" -> {
        let geometry_result =
          dynamic.field(
            named: "geometry",
            of: dynamic.optional(geometry_decoder),
          )(dynamic_value)

        let properties_result =
          dynamic.field(
            named: "properties",
            of: dynamic.optional(dynamic.dict(dynamic.string, dynamic.dynamic)),
          )(dynamic_value)
          |> result.map_error(fn(_errs) {
            [
              dynamic.DecodeError(
                expected: "Properties",
                found: "Invalid",
                path: ["properties"],
              ),
            ]
          })

        let id_result =
          dynamic.optional_field(named: "id", of: dynamic.dynamic)(
            dynamic_value,
          )
          |> result.map_error(fn(_errs) {
            [
              dynamic.DecodeError(expected: "ID", found: "Invalid", path: ["id"]),
            ]
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

        result.try(geometry_result, fn(geometry_opt) {
          result.try(properties_result, fn(properties_opt) {
            result.map(id_result, fn(id_opt) {
              Feature(geometry_opt, properties_opt, id_opt)
            })
          })
        })
      }

      _ ->
        Error([
          dynamic.DecodeError(expected: "Feature", found: type_str, path: [
            "type",
          ]),
        ])
    }
  })
}

/// Decodes a feature collection from a dynamic value.
pub fn featurecollection_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(FeatureCollection, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "FeatureCollection" ->
        dynamic.field(named: "features", of: dynamic.list(of: feature_decoder))(
          dynamic_value,
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
  })
}

/// Decodes a GeoJSON object from a dynamic value.
pub fn geojson_decoder(
  dynamic_value: dynamic.Dynamic,
) -> Result(GeoJSON, List(dynamic.DecodeError)) {
  dynamic.field(named: "type", of: dynamic.string)(dynamic_value)
  |> result.then(fn(type_str) {
    case type_str {
      "Feature" ->
        feature_decoder(dynamic_value)
        |> result.map(GeoJSONFeature)
      "FeatureCollection" ->
        featurecollection_decoder(dynamic_value)
        |> result.map(GeoJSONFeatureCollection)
      _ ->
        geometry_decoder(dynamic_value)
        |> result.map(GeoJSONGeometry)
    }
  })
}
