import birdie
import gleam/dynamic
import gleam/json
import gleam/option
import gleeunit
import gleeunit/should
import gleojson

pub fn main() {
  gleeunit.main()
}

pub type TestProperties {
  TestProperties(name: String, value: Float)
}

fn test_properties_encoder(props: TestProperties) -> json.Json {
  let TestProperties(name, value) = props
  json.object([#("name", json.string(name)), #("value", json.float(value))])
}

fn test_properties_decoder() {
  dynamic.decode2(
    TestProperties,
    dynamic.field("name", dynamic.string),
    dynamic.field("value", dynamic.float),
  )
}

pub type ParkProperties {
  ParkProperties(
    name: String,
    area_sq_km: Float,
    year_established: Int,
    is_protected: Bool,
  )
}

fn park_properties_encoder(props: ParkProperties) -> json.Json {
  let ParkProperties(name, area_sq_km, year_established, is_protected) = props
  json.object([
    #("name", json.string(name)),
    #("area_sq_km", json.float(area_sq_km)),
    #("year_established", json.int(year_established)),
    #("is_protected", json.bool(is_protected)),
  ])
}

fn park_properties_decoder() {
  dynamic.decode4(
    ParkProperties,
    dynamic.field("name", dynamic.string),
    dynamic.field("area_sq_km", dynamic.float),
    dynamic.field("year_established", dynamic.int),
    dynamic.field("is_protected", dynamic.bool),
  )
}

pub type MixedFeaturesProperties {
  CityProperties(
    name: String,
    population: Int,
    timezone: String,
    elevation: Float,
  )
  RiverProperties(name: String, length_km: Float, countries: List(String))
}

fn mixed_features_properties_encoder(
  props: MixedFeaturesProperties,
) -> json.Json {
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
        #("countries", json.array(countries, json.string)),
      ])
  }
}

fn mixed_features_properties_decoder() {
  dynamic.any([
    dynamic.decode4(
      CityProperties,
      dynamic.field("name", dynamic.string),
      dynamic.field("population", dynamic.int),
      dynamic.field("timezone", dynamic.string),
      dynamic.field("elevation", dynamic.float),
    ),
    dynamic.decode3(
      RiverProperties,
      dynamic.field("name", dynamic.string),
      dynamic.field("length_km", dynamic.float),
      dynamic.field("countries", dynamic.list(dynamic.string)),
    ),
  ])
}

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

  json.decode(
    from: encoded,
    using: gleojson.geojson_decoder(properties_decoder),
  )
  |> should.be_ok
  |> should.equal(geojson)
}

pub fn point_encode_decode_test() {
  let geojson =
    gleojson.GeoGeometry(
      gleojson.Point(gleojson.new_position_2d(lon: 1.0, lat: 2.0)),
    )

  assert_encode_decode(
    geojson,
    gleojson.properties_null_encoder,
    gleojson.properties_null_decoder,
    "point_encode_decode",
  )
}

pub fn multipoint_encode_decode_test() {
  let geojson =
    gleojson.GeoGeometry(
      gleojson.MultiPoint([
        gleojson.new_position_2d(lon: 1.0, lat: 2.0),
        gleojson.new_position_2d(lon: 3.0, lat: 4.0),
      ]),
    )

  assert_encode_decode(
    geojson,
    gleojson.properties_null_encoder,
    gleojson.properties_null_decoder,
    "multipoint_encode_decode",
  )
}

pub fn linestring_encode_decode_test() {
  let geojson =
    gleojson.GeoGeometry(
      gleojson.LineString([
        gleojson.new_position_2d(lon: 1.0, lat: 2.0),
        gleojson.new_position_2d(lon: 3.0, lat: 4.0),
      ]),
    )

  assert_encode_decode(
    geojson,
    gleojson.properties_null_encoder,
    gleojson.properties_null_decoder,
    "linestring_encode_decode",
  )
}

pub fn polygon_encode_decode_test() {
  let geojson =
    gleojson.GeoGeometry(
      gleojson.Polygon([
        [
          gleojson.new_position_2d(lon: 1.0, lat: 2.0),
          gleojson.new_position_2d(lon: 3.0, lat: 4.0),
          gleojson.new_position_2d(lon: 5.0, lat: 6.0),
          gleojson.new_position_2d(lon: 1.0, lat: 2.0),
        ],
      ]),
    )

  assert_encode_decode(
    geojson,
    gleojson.properties_null_encoder,
    gleojson.properties_null_decoder,
    "polygon_encode_decode",
  )
}

pub fn multipolygon_encode_decode_test() {
  let geojson =
    gleojson.GeoGeometry(
      gleojson.MultiPolygon([
        [
          [
            gleojson.new_position_2d(lon: 1.0, lat: 2.0),
            gleojson.new_position_2d(lon: 3.0, lat: 4.0),
            gleojson.new_position_2d(lon: 5.0, lat: 6.0),
            gleojson.new_position_2d(lon: 1.0, lat: 2.0),
          ],
        ],
        [
          [
            gleojson.new_position_2d(lon: 7.0, lat: 8.0),
            gleojson.new_position_2d(lon: 9.0, lat: 10.0),
            gleojson.new_position_2d(lon: 11.0, lat: 12.0),
            gleojson.new_position_2d(lon: 7.0, lat: 8.0),
          ],
        ],
      ]),
    )

  assert_encode_decode(
    geojson,
    gleojson.properties_null_encoder,
    gleojson.properties_null_decoder,
    "multipolygon_encode_decode",
  )
}

pub fn geometrycollection_encode_decode_test() {
  let geojson =
    gleojson.GeoGeometry(
      gleojson.GeometryCollection([
        gleojson.Point(gleojson.new_position_2d(lon: 1.0, lat: 2.0)),
        gleojson.LineString([
          gleojson.new_position_2d(lon: 3.0, lat: 4.0),
          gleojson.new_position_2d(lon: 5.0, lat: 6.0),
        ]),
      ]),
    )

  assert_encode_decode(
    geojson,
    gleojson.properties_null_encoder,
    gleojson.properties_null_decoder,
    "geometrycollection_encode_decode",
  )
}

pub fn feature_encode_decode_test() {
  let properties = TestProperties("Test Point", 42.0)

  let feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.Point(gleojson.new_position_2d(lon: 1.0, lat: 2.0)),
      ),
      properties: option.Some(properties),
      id: option.Some(gleojson.StringId("feature-id")),
    )

  let geojson = gleojson.GeoFeature(feature)

  assert_encode_decode(
    geojson,
    test_properties_encoder,
    test_properties_decoder(),
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
            gleojson.new_position_2d(lon: -119.5383, lat: 37.8651),
            gleojson.new_position_2d(lon: -119.5127, lat: 37.8777),
            gleojson.new_position_2d(lon: -119.4939, lat: 37.8685),
            gleojson.new_position_2d(lon: -119.5383, lat: 37.8651),
          ],
        ]),
      ),
      properties: option.Some(properties),
      id: option.Some(gleojson.StringId("yosemite")),
    )

  let geojson = gleojson.GeoFeature(feature)

  assert_encode_decode(
    geojson,
    park_properties_encoder,
    park_properties_decoder(),
    "real_life_feature",
  )
}

pub fn real_life_featurecollection_test() {
  let city_properties = CityProperties("Tokyo", 37_435_191, "Asia/Tokyo", 40.0)

  let city_feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.Point(gleojson.new_position_2d(lon: 139.6917, lat: 35.6895)),
      ),
      properties: option.Some(city_properties),
      id: option.Some(gleojson.StringId("tokyo")),
    )

  let river_properties =
    RiverProperties("Colorado River", 2330.0, ["USA", "Mexico"])

  let river_feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.LineString([
          gleojson.new_position_2d(lon: -115.1728, lat: 36.1147),
          gleojson.new_position_2d(lon: -116.2139, lat: 36.5674),
          gleojson.new_position_2d(lon: -117.1522, lat: 36.6567),
        ]),
      ),
      properties: option.Some(river_properties),
      id: option.Some(gleojson.StringId("colorado-river")),
    )

  let feature_collection =
    gleojson.FeatureCollection([city_feature, river_feature])

  let geojson = gleojson.GeoFeatureCollection(feature_collection)

  assert_encode_decode(
    geojson,
    mixed_features_properties_encoder,
    mixed_features_properties_decoder(),
    "real_life_featurecollection",
  )
}
