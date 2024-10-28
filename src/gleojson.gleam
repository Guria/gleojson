import decode/zero
import gleam/json
import gleam/option

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
  GeoGeometry(Geometry)
  GeoFeature(Feature(properties))
  GeoFeatureCollection(FeatureCollection(properties))
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
  let base_obj = [
    #("type", json.string("Feature")),
    #("geometry", case feature.geometry {
      option.Some(geometry) -> encode_geometry(geometry)
      option.None -> json.null()
    }),
    #("properties", case feature.properties {
      option.Some(props) -> properties_encoder(props)
      _ -> json.null()
    }),
  ]

  json.object(case feature.id {
    option.Some(StringId(id)) -> [#("id", json.string(id)), ..base_obj]
    option.Some(NumberId(id)) -> [#("id", json.float(id)), ..base_obj]
    option.None -> base_obj
  })
}

fn encode_featurecollection(
  properties_encoder: fn(properties) -> json.Json,
  collection: FeatureCollection(properties),
) -> json.Json {
  json.object([
    #("type", json.string("FeatureCollection")),
    #(
      "features",
      json.array(collection.features, fn(feature) {
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
///   let geojson = gleojson.GeoFeature(feature)
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
    GeoGeometry(geometry) -> encode_geometry(geometry)
    GeoFeature(feature) -> encode_feature(properties_encoder, feature)
    GeoFeatureCollection(collection) ->
      encode_featurecollection(properties_encoder, collection)
  }
}

fn position_decoder() {
  use decoded_list <- zero.then(zero.list(zero.float))
  case decoded_list {
    [lon, lat, alt] -> zero.success(new_position_3d(lon, lat, alt))
    [lon, lat] -> zero.success(new_position_2d(lon, lat))
    _ -> zero.failure(new_position_2d(0.0, 0.0), "list at least 2 coordinates")
  }
}

fn positions_decoder() {
  zero.list(position_decoder())
}

fn positions_list_decoder() {
  zero.list(positions_decoder())
}

fn positions_list_list_decoder() {
  zero.list(positions_list_decoder())
}

fn type_decoder() {
  zero.field("type", zero.string, zero.success)
}

fn coords_decoder(decoder, next) {
  zero.field("coordinates", decoder, next)
}

fn geometry_decoder() {
  use type_str <- zero.then(type_decoder())
  case type_str {
    "Point" -> {
      use position <- coords_decoder(position_decoder())
      zero.success(Point(position))
    }
    "MultiPoint" -> {
      use positions <- coords_decoder(positions_decoder())
      zero.success(MultiPoint(positions))
    }
    "LineString" -> {
      use positions <- coords_decoder(positions_decoder())
      zero.success(LineString(positions))
    }
    "MultiLineString" -> {
      use positions_list <- coords_decoder(positions_list_decoder())
      zero.success(MultiLineString(positions_list))
    }
    "Polygon" -> {
      use positions_list <- coords_decoder(positions_list_decoder())
      zero.success(Polygon(positions_list))
    }
    "MultiPolygon" -> {
      use positions_list_list <- coords_decoder(positions_list_list_decoder())
      zero.success(MultiPolygon(positions_list_list))
    }
    "GeometryCollection" -> {
      use geometries <- zero.field("geometries", zero.list(geometry_decoder()))
      zero.success(GeometryCollection(geometries))
    }
    _ -> zero.failure(Point(new_position_2d(0.0, 0.0)), "unknown geometry type")
  }
}

fn feature_id_decoder() {
  zero.one_of(zero.string |> zero.map(StringId), [
    zero.float |> zero.map(NumberId),
  ])
}

fn feature_decoder(properties_decoder: zero.Decoder(properties)) {
  use type_str <- zero.then(type_decoder())
  case type_str {
    "Feature" -> {
      use geometry <- zero.field("geometry", zero.optional(geometry_decoder()))
      use properties <- zero.field(
        "properties",
        zero.optional(properties_decoder),
      )
      use id <- zero.field("id", zero.optional(feature_id_decoder()))
      zero.success(Feature(geometry, properties, id))
    }
    _ ->
      zero.failure(
        Feature(option.None, option.None, option.None),
        "expected Feature",
      )
  }
}

fn featurecollection_decoder(properties_decoder: zero.Decoder(properties)) {
  use type_str <- zero.then(type_decoder())
  case type_str {
    "FeatureCollection" -> {
      use features <- zero.field(
        "features",
        zero.list(feature_decoder(properties_decoder)),
      )
      zero.success(FeatureCollection(features))
    }
    _ -> zero.failure(FeatureCollection([]), "expected FeatureCollection")
  }
}

/// Decodes a GeoJSON object from a dynamic value.
///
/// This function takes a properties decoder for Feature and FeatureCollection properties,
/// and returns a decoder for GeoJSON objects.
///
/// ## Example
///
/// ```gleam
/// import gleojson
/// import gleam/json
/// import decode/zero
/// import gleam/io
/// import gleam/string
///
/// pub type CustomProperties {
///   CustomProperties(name: String, value: Float)
/// }
///
/// pub fn custom_properties_decoder() {
///   use name <- zero.field("name", zero.string)
///   use value <- zero.field("value", zero.float)
///   CustomProperties(name: name, value: value)
///   |> zero.success
/// }
///
/// pub fn main() {
///   let json_string = "{\"type\":\"Feature\",\"geometry\":{\"type\":\"Point\",\"coordinates\":[0.0,0.0]},\"properties\":{\"name\":\"Example\",\"value\":42.0}}"
///
///   let decoded =
///     json.decode(
///       from: json_string,
///       using: zero.run(_, gleojson.geojson_decoder(custom_properties_decoder()))
///     )
///
///   case decoded {
///     Ok(geojson) -> {
///       case geojson {
///         gleojson.GeoFeature(feature) -> {
///           io.println("Decoded a feature")
///         }
///         _ -> io.println("Decoded a different type of GeoJSON object")
///       }
///     }
///     Error(error) -> {
///       io.println("Failed to decode: " <> error)
///     }
///   }
/// }
/// ```
///
/// Note: This function expects a valid GeoJSON structure.
/// Invalid or incomplete GeoJSON data will result in a decode error.
pub fn geojson_decoder(properties_decoder: zero.Decoder(properties)) {
  use type_str <- zero.then(type_decoder())
  case type_str {
    "Feature" -> feature_decoder(properties_decoder) |> zero.map(GeoFeature)
    "FeatureCollection" ->
      featurecollection_decoder(properties_decoder)
      |> zero.map(GeoFeatureCollection)
    _ -> geometry_decoder() |> zero.map(GeoGeometry)
  }
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
