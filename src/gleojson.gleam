import gleam/dynamic
import gleam/json
import gleam/option
import gleam/result

/// Represents a longitude value in degrees.
///
/// Longitude values range from -180 to 180 degrees, with positive values
/// indicating east and negative values indicating west of the Prime Meridian.
pub type Lon {
  Lon(Float)
}

/// Represents a latitude value in degrees.
///
/// Latitude values range from -90 to 90 degrees, with positive values
/// indicating north and negative values indicating south of the Equator.
pub type Lat {
  Lat(Float)
}

/// Represents an altitude value, typically in meters above sea level.
///
/// Altitude can be positive (above sea level) or negative (below sea level).
pub type Alt {
  Alt(Float)
}

/// Represents a geographic position in either 2D (longitude and latitude) or 3D (longitude, latitude, and altitude).
///
/// This type is used to define coordinates in GeoJSON objects.
pub type Position {
  Position2D(#(Lon, Lat))
  Position3D(#(Lon, Lat, Alt))
}

/// Geometry kind denominator for GeoJSON objects.
pub type Geometry

/// Feature kind denominator for GeoJSON objects.
pub type Feature

/// Represents the ID of a Feature in GeoJSON.
///
/// The ID can be either a string or a number, as per the GeoJSON specification.
pub type FeatureId {
  StringId(String)
  NumberId(Float)
}

/// Represents all possible GeoJSON objects as defined in the GeoJSON specification.
///
/// This type uses phantom types `kind` and `properties` to distinguish between
/// different GeoJSON object types and to allow for custom property types.
pub type GeoJSON(kind, properties) {
  Point(coordinates: Position)
  MultiPoint(coordinates: List(Position))
  LineString(coordinates: List(Position))
  MultiLineString(coordinates: List(List(Position)))
  Polygon(coordinates: List(List(Position)))
  MultiPolygon(coordinates: List(List(List(Position))))
  GeometryCollection(geometries: List(GeoJSON(Geometry, Nil)))
  Feature(
    geometry: option.Option(GeoJSON(Geometry, Nil)),
    properties: option.Option(properties),
    id: option.Option(FeatureId),
  )
  FeatureCollection(features: List(GeoJSON(Feature, properties)))
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

/// Encodes a GeoJSON geometry object into a JSON value.
///
/// This function is a convenience wrapper around `encode_geojson` for geometry objects.
pub fn encode_geometry(geometry: GeoJSON(Geometry, properties)) {
  encode_geojson(geometry, properties_null_encoder)
}

fn encode_feature(
  feature: GeoJSON(Feature, properties),
  properties_encoder: fn(properties) -> json.Json,
) {
  encode_geojson(feature, properties_encoder)
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
///   
///   let encoded = gleojson.encode_geojson(feature, custom_properties_encoder)
///   io.println(json.to_string(encoded))
/// }
/// ```
pub fn encode_geojson(
  geojson: GeoJSON(kind, properties),
  properties_encoder: fn(properties) -> json.Json,
) -> json.Json {
  case geojson {
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
    Feature(geometry_opt, properties_opt, id_opt) -> {
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
    FeatureCollection(features) -> {
      json.object([
        #("type", json.string("FeatureCollection")),
        #(
          "features",
          json.array(features, fn(feature) {
            encode_feature(feature, properties_encoder)
          }),
        ),
      ])
    }
  }
}

fn position_decoder() {
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
  ])
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

fn feature_id_decoder() {
  dynamic.any([
    dynamic.decode1(StringId, dynamic.string),
    dynamic.decode1(NumberId, dynamic.float),
  ])
}

/// Creates a decoder for GeoJSON geometry objects.
///
/// This function is a convenience wrapper around `geojson_decoder` for geometry objects.
pub fn geometry_decoder() -> dynamic.Decoder(GeoJSON(Geometry, Nil)) {
  geojson_decoder(properties_null_decoder)
}

fn feature_decoder(
  properties_decoder: dynamic.Decoder(properties),
) -> dynamic.Decoder(GeoJSON(Feature, properties)) {
  geojson_decoder(properties_decoder)
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
///         gleojson.Feature(_, _, _) -> {
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
pub fn geojson_decoder(properties_decoder: dynamic.Decoder(properties)) {
  fn(dyn_value: dynamic.Dynamic) -> Result(
    GeoJSON(kind, properties),
    List(dynamic.DecodeError),
  ) {
    use type_str <- result.try(type_decoder()(dyn_value))
    case type_str {
      "Point" -> dynamic.decode1(Point, coords_decoder(position_decoder()))
      "MultiPoint" ->
        dynamic.decode1(MultiPoint, coords_decoder(positions_decoder()))
      "LineString" ->
        dynamic.decode1(LineString, coords_decoder(positions_decoder()))
      "MultiLineString" ->
        dynamic.decode1(
          MultiLineString,
          coords_decoder(positions_list_decoder()),
        )
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
          dynamic.field("geometries", dynamic.list(geometry_decoder())),
        )
      "Feature" -> {
        dynamic.decode3(
          Feature,
          dynamic.field("geometry", dynamic.optional(geometry_decoder())),
          dynamic.field("properties", dynamic.optional(properties_decoder)),
          dynamic.optional_field("id", feature_id_decoder()),
        )
      }
      "FeatureCollection" ->
        dynamic.decode1(
          FeatureCollection,
          dynamic.field(
            "features",
            dynamic.list(feature_decoder(properties_decoder)),
          ),
        )
      _ -> fn(_) {
        Error([
          dynamic.DecodeError(
            expected: "one of [Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection, Feature, FeatureCollection]",
            found: type_str,
            path: ["type"],
          ),
        ])
      }
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
