import gleam/dynamic
import gleam/json
import gleam/option
import gleam/result

pub type Lon {
  Lon(Float)
}

pub type Lat {
  Lat(Float)
}

pub type Alt {
  Alt(Float)
}

pub type Position {
  Position2D(lon: Lon, lat: Lat)
  Position3D(lon: Lon, lat: Lat, alt: Alt)
}

pub type Geometry {
  Point(coordinates: Position)
  MultiPoint(coordinates: List(Position))
  LineString(coordinates: List(Position))
  MultiLineString(coordinates: List(List(Position)))
  Polygon(coordinates: List(List(Position)))
  MultiPolygon(coordinates: List(List(List(Position))))
  GeometryCollection(geometries: List(Geometry))
}

pub type FeatureId {
  StringId(String)
  NumberId(Float)
}

pub type Feature(properties) {
  Feature(
    geometry: option.Option(Geometry),
    properties: option.Option(properties),
    id: option.Option(FeatureId),
  )
}

pub type FeatureCollection(properties) {
  FeatureCollection(features: List(Feature(properties)))
}

pub type GeoJSON(properties) {
  GeoJSONGeometry(Geometry)
  GeoJSONFeature(Feature(properties))
  GeoJSONFeatureCollection(FeatureCollection(properties))
}

fn encode_position(position: Position) -> json.Json {
  case position {
    Position2D(Lon(lon), Lat(lat)) -> json.array([lon, lat], json.float)
    Position3D(Lon(lon), Lat(lat), Alt(alt)) ->
      json.array([lon, lat, alt], json.float)
  }
}

fn encode_geometry(geometry: Geometry) -> json.Json {
  case geometry {
    Point(coordinates) ->
      json.object([
        #("type", json.string("Point")),
        #("coordinates", encode_position(coordinates)),
      ])
    MultiPoint(multipoint) ->
      json.object([
        #("type", json.string("MultiPoint")),
        #("coordinates", json.array(multipoint, encode_position)),
      ])
    LineString(linestring) ->
      json.object([
        #("type", json.string("LineString")),
        #("coordinates", json.array(linestring, encode_position)),
      ])
    MultiLineString(multilinestring) ->
      json.object([
        #("type", json.string("MultiLineString")),
        #(
          "coordinates",
          json.array(multilinestring, json.array(_, encode_position)),
        ),
      ])
    Polygon(polygon) ->
      json.object([
        #("type", json.string("Polygon")),
        #("coordinates", json.array(polygon, json.array(_, encode_position))),
      ])
    MultiPolygon(multipolygon) ->
      json.object([
        #("type", json.string("MultiPolygon")),
        #(
          "coordinates",
          json.array(multipolygon, json.array(_, json.array(_, encode_position))),
        ),
      ])
    GeometryCollection(collection) ->
      json.object([
        #("type", json.string("GeometryCollection")),
        #("geometries", json.array(collection, encode_geometry)),
      ])
  }
}

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
    _ -> json.null()
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

fn encode_featurecollection(
  properties_encoder: fn(properties) -> json.Json,
  collection: FeatureCollection(properties),
) -> json.Json {
  let FeatureCollection(features) = collection
  json.object([
    #("type", json.string("FeatureCollection")),
    #(
      "features",
      json.array(features, fn(feature) {
        encode_feature(properties_encoder, feature)
      }),
    ),
  ])
}

/// Encodes a GeoJSON object into a JSON value.
///
/// This function takes a GeoJSON object and a properties encoder function,
/// and returns a JSON representation of the GeoJSON object.
///
/// ## Example
///
/// ```gleam
/// import gleojson
/// import gleam/json
/// import gleam/option
/// import gleam/io
///
/// pub type CustomProperties {
///   CustomProperties(name: String, value: Float)
/// }
///
/// pub fn custom_properties_encoder(props: CustomProperties) -> json.Json {
///   json.object([
///     #("name", json.string(props.name)),
///     #("value", json.float(props.value)),
///   ])
/// }
///
/// pub fn main() {
///   let point = gleojson.Point(gleojson.new_position_2d(lon: 0.0, lat: 0.0))
///   let properties = CustomProperties("Example", 42.0)
///   let feature = gleojson.Feature(
///     geometry: option.Some(point),
///     properties: option.Some(properties),
///     id: option.Some(gleojson.StringId("example-point"))
///   )
///   let geojson = gleojson.GeoJSONFeature(feature)
///
///   let encoded = gleojson.encode_geojson(geojson, custom_properties_encoder)
///   io.println(json.to_string(encoded))
/// }
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

fn position_decoder() {
  fn(dyn_value) {
    use list <- result.try(dynamic.list(dynamic.float)(dyn_value))
    case list {
      [lon, lat, alt] -> Ok(new_position_3d(lon, lat, alt))
      [lon, lat] -> Ok(new_position_2d(lon, lat))
      _ ->
        Error([
          dynamic.DecodeError(
            expected: "list at least 2 coordinates",
            found: dynamic.classify(dyn_value),
            path: [],
          ),
        ])
    }
  }
}

fn positions_decoder() {
  dynamic.list(position_decoder())
}

fn positions_list_decoder() {
  dynamic.list(positions_decoder())
}

fn positions_list_list_decoder() {
  dynamic.list(positions_list_decoder())
}

fn type_decoder() {
  dynamic.field("type", dynamic.string)
}

fn coords_decoder(decoder) {
  dynamic.field("coordinates", decoder)
}

fn geometry_decoder(dyn_value: dynamic.Dynamic) {
  use type_str <- result.try(type_decoder()(dyn_value))
  case type_str {
    "Point" -> dynamic.decode1(Point, coords_decoder(position_decoder()))
    "MultiPoint" ->
      dynamic.decode1(MultiPoint, coords_decoder(positions_decoder()))
    "LineString" ->
      dynamic.decode1(LineString, coords_decoder(positions_decoder()))
    "MultiLineString" ->
      dynamic.decode1(MultiLineString, coords_decoder(positions_list_decoder()))
    "Polygon" ->
      dynamic.decode1(Polygon, coords_decoder(positions_list_decoder()))
    "MultiPolygon" ->
      dynamic.decode1(
        MultiPolygon,
        coords_decoder(positions_list_list_decoder()),
      )
    "GeometryCollection" ->
      dynamic.decode1(
        GeometryCollection,
        dynamic.field("geometries", dynamic.list(geometry_decoder)),
      )
    _ -> fn(_) {
      Error([
        dynamic.DecodeError(
          expected: "one of [Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection]",
          found: type_str,
          path: ["type"],
        ),
      ])
    }
  }(dyn_value)
}

fn feature_id_decoder() {
  dynamic.any([
    dynamic.decode1(StringId, dynamic.string),
    dynamic.decode1(NumberId, dynamic.float),
  ])
}

fn feature_decoder(properties_decoder: dynamic.Decoder(properties)) {
  fn(dyn_value: dynamic.Dynamic) -> Result(
    Feature(properties),
    List(dynamic.DecodeError),
  ) {
    use type_str <- result.try(type_decoder()(dyn_value))
    case type_str {
      "Feature" -> {
        dynamic.decode3(
          Feature,
          dynamic.field("geometry", dynamic.optional(geometry_decoder)),
          dynamic.field("properties", dynamic.optional(properties_decoder)),
          dynamic.optional_field("id", feature_id_decoder()),
        )(dyn_value)
      }
      _ ->
        Error([
          dynamic.DecodeError(expected: "Feature", found: type_str, path: [
            "type",
          ]),
        ])
    }
  }
}

fn featurecollection_decoder(properties_decoder: dynamic.Decoder(properties)) {
  fn(dyn_value: dynamic.Dynamic) -> Result(
    FeatureCollection(properties),
    List(dynamic.DecodeError),
  ) {
    use type_str <- result.try(type_decoder()(dyn_value))
    case type_str {
      "FeatureCollection" ->
        dynamic.decode1(
          FeatureCollection,
          dynamic.field(
            "features",
            dynamic.list(feature_decoder(properties_decoder)),
          ),
        )(dyn_value)
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
}

/// Decodes a GeoJSON object from a dynamic value.
///
/// This function takes a dynamic value (typically parsed from JSON) and a properties decoder,
/// and attempts to decode it into a GeoJSON object.
///
/// ## Example
///
/// ```gleam
/// import gleojson
/// import gleam/json
/// import gleam/result
/// import gleam/dynamic
/// import gleam/io
/// import gleam/string
///
/// pub type CustomProperties {
///   CustomProperties(name: String, value: Float)
/// }
///
/// pub fn custom_properties_decoder() {
///   dynamic.decode2(
///     CustomProperties,
///     dynamic.field("name", dynamic.string),
///     dynamic.field("value", dynamic.float),
///   )
/// }
///
/// pub fn main() {
///   let json_string = "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[0.0,0.0]},\"properties\":{\"name\":\"Example\",\"value\":42.0}}"
///
///   let decoded =
///     json.decode(
///       from: json_string,
///       using: gleojson.geojson_decoder(custom_properties_decoder())
///     )
///
///   case decoded {
///     Ok(geojson) -> {
///       // Work with the decoded GeoJSON object
///       case geojson {
///         gleojson.GeoJSONFeature(feature) -> {
///           io.println("Decoded a feature")
///         }
///         _ -> io.println("Decoded a different type of GeoJSON object")
///       }
///     }
///     Error(errors) -> {
///       // Handle decoding errors
///       io.println("Failed to decode: " <> string.join(errors, ", "))
///     }
///   }
/// }
/// ```
///
/// Note: This function expects a valid GeoJSON structure. Invalid or incomplete
/// GeoJSON data will result in a decode error.
pub fn geojson_decoder(properties_decoder: dynamic.Decoder(properties)) {
  fn(dyn_value: dynamic.Dynamic) -> Result(
    GeoJSON(properties),
    List(dynamic.DecodeError),
  ) {
    use type_str <- result.try(type_decoder()(dyn_value))
    case type_str {
      "Feature" ->
        dynamic.decode1(GeoJSONFeature, feature_decoder(properties_decoder))
      "FeatureCollection" ->
        dynamic.decode1(
          GeoJSONFeatureCollection,
          featurecollection_decoder(properties_decoder),
        )
      _ -> dynamic.decode1(GeoJSONGeometry, geometry_decoder)
    }(dyn_value)
  }
}

/// Encodes null properties for Features and FeatureCollections.
///
/// This is a utility function that can be used as the `properties_encoder`
/// argument for `encode_geojson` when you don't need to encode any properties.
pub fn properties_null_encoder(_props) {
  json.null()
}

/// Decodes null properties for Features and FeatureCollections.
///
/// This is a utility function that can be used as the `properties_decoder`
/// argument for `geojson_decoder` when you don't need to decode any properties.
pub fn properties_null_decoder(_dyn) -> Result(Nil, List(dynamic.DecodeError)) {
  Ok(Nil)
}

/// Creates a 2D Position object from longitude and latitude values.
///
/// This function is a convenience helper for creating a Position object
/// with two dimensions (longitude and latitude).
pub fn new_position_2d(lon lon, lat lat) {
  Position2D(Lon(lon), Lat(lat))
}

/// Creates a 3D Position object from longitude, latitude, and altitude values.
///
/// This function is a convenience helper for creating a Position object
/// with three dimensions (longitude, latitude, and altitude).
pub fn new_position_3d(lon lon, lat lat, alt alt) {
  Position3D(Lon(lon), Lat(lat), Alt(alt))
}
