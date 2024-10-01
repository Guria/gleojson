import birdie
import gleam/dynamic
import gleam/json
import gleam/option
import gleam/result
import gleeunit
import gleeunit/should

import gleojson

pub fn main() {
  gleeunit.main()
}

// Define custom property types for tests

// TestProperties for feature_encode_decode_test
pub type TestProperties {
  TestProperties(name: String, value: Float)
}

// Encoder for TestProperties
fn test_properties_encoder(props: TestProperties) -> json.Json {
  let TestProperties(name, value) = props
  json.object([#("name", json.string(name)), #("value", json.float(value))])
}

/// Decoder for TestProperties
fn test_properties_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(TestProperties, List(dynamic.DecodeError)) {
  use name <- result.try(dynamic.field(named: "name", of: dynamic.string)(
    dyn_value,
  ))
  use value <- result.try(dynamic.field(named: "value", of: dynamic.float)(
    dyn_value,
  ))

  Ok(TestProperties(name, value))
}

// ParkProperties for real_life_feature_test
pub type ParkProperties {
  ParkProperties(
    name: String,
    area_sq_km: Float,
    year_established: Int,
    is_protected: Bool,
  )
}

// Encoder for ParkProperties
fn park_properties_encoder(props: ParkProperties) -> json.Json {
  let ParkProperties(name, area_sq_km, year_established, is_protected) = props
  json.object([
    #("name", json.string(name)),
    #("area_sq_km", json.float(area_sq_km)),
    #("year_established", json.int(year_established)),
    #("is_protected", json.bool(is_protected)),
  ])
}

// Decoder for ParkProperties
fn park_properties_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(ParkProperties, List(dynamic.DecodeError)) {
  use name <- result.try(dynamic.field(named: "name", of: dynamic.string)(
    dyn_value,
  ))
  use area_sq_km <- result.try(dynamic.field(
    named: "area_sq_km",
    of: dynamic.float,
  )(dyn_value))
  use year_established <- result.try(dynamic.field(
    named: "year_established",
    of: dynamic.int,
  )(dyn_value))
  use is_protected <- result.try(dynamic.field(
    named: "is_protected",
    of: dynamic.bool,
  )(dyn_value))
  Ok(ParkProperties(name, area_sq_km, year_established, is_protected))
}

// Properties type for real_life_featurecollection_test
pub type Properties {
  CityProperties(
    name: String,
    population: Int,
    timezone: String,
    elevation: Float,
  )
  RiverProperties(name: String, length_km: Float, countries: List(String))
}

// Encoder for Properties
fn properties_encoder(props: Properties) -> json.Json {
  case props {
    CityProperties(name, population, timezone, elevation) ->
      json.object([
        #("name", json.string(name)),
        #("population", json.int(population)),
        #("timezone", json.string(timezone)),
        #("elevation", json.float(elevation)),
      ])
    RiverProperties(name, length_km, countries) ->
      json.object([
        #("name", json.string(name)),
        #("length_km", json.float(length_km)),
        #("countries", json.array(countries, of: json.string)),
      ])
  }
}

// Decoder for Properties
fn properties_decoder(
  dyn_value: dynamic.Dynamic,
) -> Result(Properties, List(dynamic.DecodeError)) {
  use name <- result.try(dynamic.field(named: "name", of: dynamic.string)(
    dyn_value,
  ))
  // Try decoding as CityProperties
  let population_result =
    dynamic.field(named: "population", of: dynamic.int)(dyn_value)
  let timezone_result =
    dynamic.field(named: "timezone", of: dynamic.string)(dyn_value)
  let elevation_result =
    dynamic.field(named: "elevation", of: dynamic.float)(dyn_value)
  case population_result, timezone_result, elevation_result {
    Ok(population), Ok(timezone), Ok(elevation) ->
      Ok(CityProperties(name, population, timezone, elevation))
    _, _, _ -> {
      // Try decoding as RiverProperties
      let length_km_result =
        dynamic.field(named: "length_km", of: dynamic.float)(dyn_value)
      let countries_result =
        dynamic.field(named: "countries", of: dynamic.list(of: dynamic.string))(
          dyn_value,
        )
      case length_km_result, countries_result {
        Ok(length_km), Ok(countries) ->
          Ok(RiverProperties(name, length_km, countries))
        _, _ ->
          Error([
            dynamic.DecodeError(
              expected: "Properties",
              found: "Invalid",
              path: [],
            ),
          ])
      }
    }
  }
}

// General assertion function for encoding and decoding
fn assert_encode_decode(
  geojson: gleojson.GeoJSON(properties),
  properties_encoder: fn(properties) -> json.Json,
  properties_decoder: dynamic.Decoder(properties),
  name: String,
) {
  let encoded =
    gleojson.encode_geojson(geojson, properties_encoder)
    |> json.to_string

  birdie.snap(encoded, name)

  json.decode(from: encoded, using: gleojson.geojson_decoder(
    properties_decoder,
    _,
  ))
  |> should.be_ok
  |> should.equal(geojson)
}

// Test functions for separate geometries

pub fn point_encode_decode_test() {
  let geojson = gleojson.GeoJSONGeometry(gleojson.Point([1.0, 2.0]))

  // Since there are no properties, use the unit type `Nil`
  let properties_encoder = fn(_props) { json.null() }
  let properties_decoder = fn(_dyn_value) { Ok(Nil) }

  assert_encode_decode(
    geojson,
    properties_encoder,
    properties_decoder,
    "point_encode_decode",
  )
}

pub fn multipoint_encode_decode_test() {
  let geojson =
    gleojson.GeoJSONGeometry(gleojson.MultiPoint([[1.0, 2.0], [3.0, 4.0]]))

  let properties_encoder = fn(_props) { json.null() }
  let properties_decoder = fn(_dyn_value) { Ok(Nil) }

  assert_encode_decode(
    geojson,
    properties_encoder,
    properties_decoder,
    "multipoint_encode_decode",
  )
}

pub fn linestring_encode_decode_test() {
  let geojson =
    gleojson.GeoJSONGeometry(gleojson.LineString([[1.0, 2.0], [3.0, 4.0]]))

  let properties_encoder = fn(_props) { json.null() }
  let properties_decoder = fn(_dyn_value) { Ok(Nil) }

  assert_encode_decode(
    geojson,
    properties_encoder,
    properties_decoder,
    "linestring_encode_decode",
  )
}

pub fn polygon_encode_decode_test() {
  let geojson =
    gleojson.GeoJSONGeometry(
      gleojson.Polygon([[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [1.0, 2.0]]]),
    )

  let properties_encoder = fn(_props) { json.null() }
  let properties_decoder = fn(_dyn_value) { Ok(Nil) }

  assert_encode_decode(
    geojson,
    properties_encoder,
    properties_decoder,
    "polygon_encode_decode",
  )
}

pub fn multipolygon_encode_decode_test() {
  let geojson =
    gleojson.GeoJSONGeometry(
      gleojson.MultiPolygon([
        [[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [1.0, 2.0]]],
        [[[7.0, 8.0], [9.0, 10.0], [11.0, 12.0], [7.0, 8.0]]],
      ]),
    )

  let properties_encoder = fn(_props) { json.null() }
  let properties_decoder = fn(_dyn_value) { Ok(Nil) }

  assert_encode_decode(
    geojson,
    properties_encoder,
    properties_decoder,
    "multipolygon_encode_decode",
  )
}

pub fn geometrycollection_encode_decode_test() {
  let geojson =
    gleojson.GeoJSONGeometry(
      gleojson.GeometryCollection([
        gleojson.Point([1.0, 2.0]),
        gleojson.LineString([[3.0, 4.0], [5.0, 6.0]]),
      ]),
    )

  let properties_encoder = fn(_props) { json.null() }
  let properties_decoder = fn(_dyn_value) { Ok(Nil) }

  assert_encode_decode(
    geojson,
    properties_encoder,
    properties_decoder,
    "geometrycollection_encode_decode",
  )
}

// Existing test functions...

pub fn feature_encode_decode_test() {
  let properties = TestProperties("Test Point", 42.0)

  let feature =
    gleojson.Feature(
      geometry: option.Some(gleojson.Point([1.0, 2.0])),
      properties: option.Some(properties),
      id: option.Some(gleojson.StringId("feature-id")),
    )

  let geojson = gleojson.GeoJSONFeature(feature)

  assert_encode_decode(
    geojson,
    test_properties_encoder,
    test_properties_decoder,
    "feature_encode_decode",
  )
}

pub fn real_life_feature_test() {
  let properties = ParkProperties("Yosemite National Park", 3029.87, 1890, True)

  let feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.Polygon([
          [
            [-119.5383, 37.8651],
            [-119.5127, 37.8777],
            [-119.4939, 37.8685],
            [-119.5383, 37.8651],
          ],
        ]),
      ),
      properties: option.Some(properties),
      id: option.Some(gleojson.StringId("yosemite")),
    )

  let geojson = gleojson.GeoJSONFeature(feature)

  assert_encode_decode(
    geojson,
    park_properties_encoder,
    park_properties_decoder,
    "real_life_feature",
  )
}

pub fn real_life_featurecollection_test() {
  let city_properties = CityProperties("Tokyo", 37_435_191, "Asia/Tokyo", 40.0)

  let city_feature =
    gleojson.Feature(
      geometry: option.Some(gleojson.Point([139.6917, 35.6895])),
      properties: option.Some(city_properties),
      id: option.Some(gleojson.StringId("tokyo")),
    )

  let river_properties =
    RiverProperties("Colorado River", 2330.0, ["USA", "Mexico"])

  let river_feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.LineString([
          [-115.1728, 36.1147],
          [-116.2139, 36.5674],
          [-117.1522, 36.6567],
        ]),
      ),
      properties: option.Some(river_properties),
      id: option.Some(gleojson.StringId("colorado-river")),
    )

  let feature_collection =
    gleojson.FeatureCollection([city_feature, river_feature])

  let geojson = gleojson.GeoJSONFeatureCollection(feature_collection)

  assert_encode_decode(
    geojson,
    properties_encoder,
    properties_decoder,
    "real_life_featurecollection",
  )
}
