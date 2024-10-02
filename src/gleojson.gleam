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
  Position2D(#(Lon, Lat))
  Position3D(#(Lon, Lat, Alt))
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

/// Creates a 2D Position object from longitude and latitude values.
///
/// This function is a convenience helper for creating a Position object
/// with two dimensions (longitude and latitude).
///
/// ## Arguments
///
/// - `lon`: The longitude value as a Float.
/// - `lat`: The latitude value as a Float.
///
/// ## Returns
///
/// A Position object representing a 2D coordinate.
///
/// ## Example
///
/// ```gleam
/// import gleojson
///
/// pub fn main() {
///   let position = gleojson.position_2d(lon: 125.6, lat: 10.1)
///   // Use this position in your GeoJSON objects, e.g., in a Point geometry
///   let point = gleojson.Point(coordinates: position)
/// }
/// ```
pub fn position_2d(lon lon: Float, lat lat: Float) -> Position {
  Position2D(#(Lon(lon), Lat(lat)))
}

/// Creates a 3D Position object from longitude, latitude, and altitude values.
///
/// This function is a convenience helper for creating a Position object
/// with three dimensions (longitude, latitude, and altitude).
///
/// ## Arguments
///
/// - `lon`: The longitude value as a Float.
/// - `lat`: The latitude value as a Float.
/// - `alt`: The altitude value as a Float.
///
/// ## Returns
///
/// A Position object representing a 3D coordinate.
///
/// ## Example
///
/// ```gleam
/// import gleojson
///
/// pub fn main() {
///   let position = gleojson.position_3d(lon: 125.6, lat: 10.1, alt: 100.0)
///   // Use this position in your GeoJSON objects, e.g., in a Point geometry
///   let point = gleojson.Point(coordinates: position)
/// }
/// ```
pub fn position_3d(lon lon: Float, lat lat: Float, alt alt: Float) -> Position {
  Position3D(#(Lon(lon), Lat(lat), Alt(alt)))
}

fn encode_position(position: Position) -> json.Json {
  case position {
    Position2D(#(Lon(lon), Lat(lat))) -> json.array([lon, lat], json.float)
    Position3D(#(Lon(lon), Lat(lat), Alt(alt))) ->
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
          json.array(multilinestring, fn(line) {
            json.array(line, encode_position)
          }),
        ),
      ])
    Polygon(polygon) ->
      json.object([
        #("type", json.string("Polygon")),
        #(
          "coordinates",
          json.array(polygon, fn(ring) { json.array(ring, encode_position) }),
        ),
      ])
    MultiPolygon(multipolygon) ->
      json.object([
        #("type", json.string("MultiPolygon")),
        #(
          "coordinates",
          json.array(multipolygon, fn(polygon) {
            json.array(polygon, fn(ring) { json.array(ring, encode_position) })
          }),
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
/// ## Arguments
///
/// - `geojson`: The GeoJSON object to encode.
/// - `properties_encoder`: A function that encodes the properties of Features and FeatureCollections.
///
/// ## Returns
///
/// A JSON representation of the GeoJSON object.
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
///   let point = gleojson.Point(gleojson.position_2d(lon: 0.0, lat: 0.0))
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

fn position_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(Position, List(dynamic.DecodeError)) {
  dynamic.any([
    dynamic.decode1(
      Position3D,
      dynamic.tuple3(
        dynamic.decode1(Lon, dynamic.float),
        dynamic.decode1(Lat, dynamic.float),
        dynamic.decode1(Alt, dynamic.float),
      ),
    ),
    dynamic.decode1(
      Position2D,
      dynamic.tuple2(
        dynamic.decode1(Lon, dynamic.float),
        dynamic.decode1(Lat, dynamic.float),
      ),
    ),
  ])(dyn_value)
}

fn positions_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(List(Position), List(dynamic.DecodeError)) {
  dynamic.list(position_decoder)(dyn_value)
}

fn positions_list_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(List(List(Position)), List(dynamic.DecodeError)) {
  dynamic.list(positions_decoder)(dyn_value)
}

fn positions_list_list_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(List(List(List(Position))), List(dynamic.DecodeError)) {
  dynamic.list(positions_list_decoder)(dyn_value)
}

fn decode_type_field(
  dyn_value: dynamic.Dynamic,
) -> Result(String, List(dynamic.DecodeError)) {
  dynamic.field("type", dynamic.string)(dyn_value)
}

fn geometry_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(Geometry, List(dynamic.DecodeError)) {
  use type_str <- result.try(decode_type_field(dyn_value))
  case type_str {
    "Point" ->
      dynamic.field("coordinates", position_decoder)(dyn_value)
      |> result.map(Point)
    "MultiPoint" ->
      dynamic.field("coordinates", positions_decoder)(dyn_value)
      |> result.map(MultiPoint)
    "LineString" ->
      dynamic.field("coordinates", positions_decoder)(dyn_value)
      |> result.map(LineString)
    "MultiLineString" ->
      dynamic.field("coordinates", positions_list_decoder)(dyn_value)
      |> result.map(MultiLineString)
    "Polygon" ->
      dynamic.field("coordinates", positions_list_decoder)(dyn_value)
      |> result.map(Polygon)
    "MultiPolygon" ->
      dynamic.field("coordinates", positions_list_list_decoder)(dyn_value)
      |> result.map(MultiPolygon)
    "GeometryCollection" ->
      dynamic.field("geometries", dynamic.list(geometry_decoder))(dyn_value)
      |> result.map(GeometryCollection)
    _ ->
      Error([
        dynamic.DecodeError(
          expected: "one of [Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection]",
          found: type_str,
          path: ["type"],
        ),
      ])
  }
}

fn feature_id_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(FeatureId, List(dynamic.DecodeError)) {
  dynamic.any([
    dynamic.decode1(StringId, dynamic.string),
    dynamic.decode1(NumberId, dynamic.float),
  ])(dyn_value)
}

fn feature_decoder(properties_decoder: dynamic.Decoder(properties)) {
  fn(dyn_value: dynamic.Dynamic) -> Result(
    Feature(properties),
    List(dynamic.DecodeError),
  ) {
    use type_str <- result.try(decode_type_field(dyn_value))
    case type_str {
      "Feature" -> {
        dynamic.decode3(
          Feature,
          dynamic.field("geometry", dynamic.optional(geometry_decoder)),
          dynamic.field("properties", dynamic.optional(properties_decoder)),
          dynamic.optional_field("id", feature_id_decoder),
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
    use type_str <- result.try(decode_type_field(dyn_value))
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
/// ## Arguments
///
/// - `properties_decoder`: A function that decodes the properties of Features and FeatureCollections.
///
/// ## Returns
///
/// A function that takes a dynamic value and returns a Result containing either
/// the decoded GeoJSON object or a list of decode errors.
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
/// pub fn custom_properties_decoder(
///   dyn: dynamic.Dynamic,
/// ) -> Result(CustomProperties, List(dynamic.DecodeError)) {
///   dynamic.decode2(
///     CustomProperties,
///     dynamic.field("name", dynamic.string),
///     dynamic.field("value", dynamic.float),
///   )(dyn)
/// }
///
/// pub fn main() {
///   let json_string = "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[0.0,0.0]},\"properties\":{\"name\":\"Example\",\"value\":42.0}}"
///   
///   let decoded = 
///     json.decode(
///       from: json_string,
///       using: gleojson.geojson_decoder(custom_properties_decoder)
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
    use type_str <- result.try(decode_type_field(dyn_value))
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
///
/// ## Returns
///
/// A JSON null value.
///
/// ## Example
///
/// ```gleam
/// import gleojson
/// import gleam/json
/// import gleam/option
///
/// pub fn main() {
///   let point = gleojson.Point([0.0, 0.0])
///   let feature = gleojson.Feature(
///     geometry: option.Some(point),
///     properties: option.None,
///     id: option.None
///   )
///   let geojson = gleojson.GeoJSONFeature(feature)
///   
///   let encoded = gleojson.encode_geojson(geojson, gleojson.properties_null_encoder)
///   // The "properties" field in the resulting JSON will be null
/// }
/// ```
pub fn properties_null_encoder(_props) {
  json.null()
}

/// Decodes null properties for Features and FeatureCollections.
///
/// This is a utility function that can be used as the `properties_decoder`
/// argument for `geojson_decoder` when you don't need to decode any properties.
///
/// ## Returns
///
/// Always returns `Ok(Nil)`.
///
/// ## Example
///
/// ```gleam
/// import gleojson
/// import gleam/json
/// import gleam/result
///
/// pub fn main() {
///   let json_string = "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[0.0,0.0]},\"properties\":null}"
///   
///   let decoded = 
///     json.decode(
///       from: json_string,
///       using: gleojson.geojson_decoder(gleojson.properties_null_decoder)
///     )
///   
///   // The "properties" field in the decoded Feature will be None
/// }
/// ```
pub fn properties_null_decoder(_dyn) -> Result(Nil, List(dynamic.DecodeError)) {
  Ok(Nil)
}
