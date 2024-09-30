import birdie
import gleam/dict
import gleam/dynamic
import gleam/json
import gleam/option
import gleeunit
import gleeunit/should

import gleojson

pub fn main() {
  gleeunit.main()
}

fn assert_encode_decode(geojson: gleojson.GeoJSON, name: String) {
  let encoded = gleojson.encode_geojson(geojson) |> json.to_string
  birdie.snap(encoded, name)
  json.decode(from: encoded, using: gleojson.geojson_decoder)
  |> should.be_ok
  |> should.equal(geojson)
}

pub fn point_encode_decode_test() {
  gleojson.GeoJSONGeometry(gleojson.Point([1.0, 2.0]))
  |> assert_encode_decode("point_encode_decode")
}

pub fn multipoint_encode_decode_test() {
  gleojson.GeoJSONGeometry(gleojson.MultiPoint([[1.0, 2.0], [3.0, 4.0]]))
  |> assert_encode_decode("multipoint_encode_decode")
}

pub fn linestring_encode_decode_test() {
  gleojson.GeoJSONGeometry(gleojson.LineString([[1.0, 2.0], [3.0, 4.0]]))
  |> assert_encode_decode("linestring_encode_decode")
}

pub fn polygon_encode_decode_test() {
  gleojson.GeoJSONGeometry(
    gleojson.Polygon([[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [1.0, 2.0]]]),
  )
  |> assert_encode_decode("polygon_encode_decode")
}

pub fn multipolygon_encode_decode_test() {
  gleojson.GeoJSONGeometry(
    gleojson.MultiPolygon([
      [[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [1.0, 2.0]]],
      [[[7.0, 8.0], [9.0, 10.0], [11.0, 12.0], [7.0, 8.0]]],
    ]),
  )
  |> assert_encode_decode("multipolygon_encode_decode")
}

pub fn geometrycollection_encode_decode_test() {
  gleojson.GeoJSONGeometry(
    gleojson.GeometryCollection([
      gleojson.Point([1.0, 2.0]),
      gleojson.LineString([[3.0, 4.0], [5.0, 6.0]]),
    ]),
  )
  |> assert_encode_decode("geometrycollection_encode_decode")
}

pub fn feature_encode_decode_test() {
  // let properties =
  //   dict.from_list([
  //     #("name", dynamic.from("Test Point")),
  //     #("value", dynamic.from(42)),
  //   ])

  gleojson.GeoJSONFeature(gleojson.Feature(
    geometry: option.Some(gleojson.Point([1.0, 2.0])),
    properties: option.None,
    id: option.Some(gleojson.StringId("feature-id")),
  ))
  |> assert_encode_decode("feature_encode_decode")
}

pub fn featurecollection_encode_decode_test() {
  // let properties =
  //   dict.from_list([
  //     #("name", dynamic.from("Test Point")),
  //     #("value", dynamic.from(42)),
  //   ])

  gleojson.GeoJSONFeatureCollection(
    gleojson.FeatureCollection([
      gleojson.Feature(
        geometry: option.Some(gleojson.Point([1.0, 2.0])),
        properties: option.None,
        id: option.Some(gleojson.StringId("feature-id")),
      ),
    ]),
  )
  |> assert_encode_decode("featurecollection_encode_decode")
}

pub fn invalid_type_decode_test() {
  dynamic.from(
    dict.from_list([
      #("type", dynamic.from("InvalidType")),
      #("coordinates", dynamic.from([1.0, 2.0])),
    ]),
  )
  |> gleojson.geojson_decoder
  |> should.be_error
}

pub fn invalid_coordinates_decode_test() {
  dynamic.from(
    dict.from_list([
      #("type", dynamic.from("Point")),
      #("coordinates", dynamic.from("invalid coordinates")),
    ]),
  )
  |> gleojson.geojson_decoder
  |> should.be_error
}

pub fn featurecollection_decode_test() {
  let json_string =
    "
  {
    \"type\": \"FeatureCollection\",
    \"features\": [{
      \"type\": \"Feature\",
      \"geometry\": {
        \"type\": \"Point\",
        \"coordinates\": [102.0, 0.5]
      },
      \"properties\": {
        \"prop0\": \"value0\"
      }
    }, {
      \"type\": \"Feature\",
      \"geometry\": {
        \"type\": \"LineString\",
        \"coordinates\": [
          [102.0, 0.0],
          [103.0, 1.0],
          [104.0, 0.0],
          [105.0, 1.0]
        ]
      },
      \"properties\": {
        \"prop0\": \"value0\",
        \"prop1\": 0.0
      }
    }, {
      \"type\": \"Feature\",
      \"geometry\": {
        \"type\": \"Polygon\",
        \"coordinates\": [
          [
            [100.0, 0.0],
            [101.0, 0.0],
            [101.0, 1.0],
            [100.0, 1.0],
            [100.0, 0.0]
          ]
        ]
      },
      \"properties\": {
        \"prop0\": \"value0\",
        \"prop1\": {
          \"this\": \"that\"
        }
      }
    }]
  }
  "

  // Decode the JSON string into a Dynamic value
  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  // Ensure decoding was successful
  let decoded_geojson =
    decode_result
    |> should.be_ok

  // Construct the expected GeoJSON data structure
  let point_feature =
    gleojson.Feature(
      geometry: option.Some(gleojson.Point([102.0, 0.5])),
      properties: option.Some(
        dict.from_list([#("prop0", dynamic.from("value0"))]),
      ),
      id: option.None,
    )

  let linestring_feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.LineString([
          [102.0, 0.0],
          [103.0, 1.0],
          [104.0, 0.0],
          [105.0, 1.0],
        ]),
      ),
      properties: option.Some(
        dict.from_list([
          #("prop0", dynamic.from("value0")),
          #("prop1", dynamic.from(0.0)),
        ]),
      ),
      id: option.None,
    )

  let polygon_feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.Polygon([
          [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
        ]),
      ),
      properties: option.Some(
        dict.from_list([
          #("prop0", dynamic.from("value0")),
          #(
            "prop1",
            dynamic.from(
              dynamic.from(dict.from_list([#("this", dynamic.from("that"))])),
            ),
          ),
        ]),
      ),
      id: option.None,
    )

  let expected_geojson =
    gleojson.GeoJSONFeatureCollection(
      gleojson.FeatureCollection([
        point_feature,
        linestring_feature,
        polygon_feature,
      ]),
    )

  // Compare the decoded GeoJSON with the expected structure
  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn point_example_test() {
  let json_string =
    "
  {
    \"type\": \"Point\",
    \"coordinates\": [100.0, 0.0]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson = gleojson.GeoJSONGeometry(gleojson.Point([100.0, 0.0]))

  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn linestring_example_test() {
  let json_string =
    "
  {
    \"type\": \"LineString\",
    \"coordinates\": [
      [100.0, 0.0],
      [101.0, 1.0]
    ]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson =
    gleojson.GeoJSONGeometry(gleojson.LineString([[100.0, 0.0], [101.0, 1.0]]))

  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn polygon_no_holes_example_test() {
  let json_string =
    "
  {
    \"type\": \"Polygon\",
    \"coordinates\": [
      [
        [100.0, 0.0],
        [101.0, 0.0],
        [101.0, 1.0],
        [100.0, 1.0],
        [100.0, 0.0]
      ]
    ]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson =
    gleojson.GeoJSONGeometry(
      gleojson.Polygon([
        [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
      ]),
    )

  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn polygon_with_holes_example_test() {
  let json_string =
    "
  {
    \"type\": \"Polygon\",
    \"coordinates\": [
      [
        [100.0, 0.0],
        [101.0, 0.0],
        [101.0, 1.0],
        [100.0, 1.0],
        [100.0, 0.0]
      ],
      [
        [100.8, 0.8],
        [100.8, 0.2],
        [100.2, 0.2],
        [100.2, 0.8],
        [100.8, 0.8]
      ]
    ]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson =
    gleojson.GeoJSONGeometry(
      gleojson.Polygon([
        [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
        [[100.8, 0.8], [100.8, 0.2], [100.2, 0.2], [100.2, 0.8], [100.8, 0.8]],
      ]),
    )

  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn multipoint_example_test() {
  let json_string =
    "
  {
    \"type\": \"MultiPoint\",
    \"coordinates\": [
      [100.0, 0.0],
      [101.0, 1.0]
    ]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson =
    gleojson.GeoJSONGeometry(gleojson.MultiPoint([[100.0, 0.0], [101.0, 1.0]]))

  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn multilinestring_example_test() {
  let json_string =
    "
  {
    \"type\": \"MultiLineString\",
    \"coordinates\": [
      [
        [100.0, 0.0],
        [101.0, 1.0]
      ],
      [
        [102.0, 2.0],
        [103.0, 3.0]
      ]
    ]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson =
    gleojson.GeoJSONGeometry(
      gleojson.MultiLineString([
        [[100.0, 0.0], [101.0, 1.0]],
        [[102.0, 2.0], [103.0, 3.0]],
      ]),
    )

  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn multipolygon_example_test() {
  let json_string =
    "
  {
    \"type\": \"MultiPolygon\",
    \"coordinates\": [
      [
        [
          [102.0, 2.0],
          [103.0, 2.0],
          [103.0, 3.0],
          [102.0, 3.0],
          [102.0, 2.0]
        ]
      ],
      [
        [
          [100.0, 0.0],
          [101.0, 0.0],
          [101.0, 1.0],
          [100.0, 1.0],
          [100.0, 0.0]
        ],
        [
          [100.2, 0.2],
          [100.2, 0.8],
          [100.8, 0.8],
          [100.8, 0.2],
          [100.2, 0.2]
        ]
      ]
    ]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson =
    gleojson.GeoJSONGeometry(
      gleojson.MultiPolygon([
        [[[102.0, 2.0], [103.0, 2.0], [103.0, 3.0], [102.0, 3.0], [102.0, 2.0]]],
        [
          [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
          [[100.2, 0.2], [100.2, 0.8], [100.8, 0.8], [100.8, 0.2], [100.2, 0.2]],
        ],
      ]),
    )

  decoded_geojson
  |> should.equal(expected_geojson)
}

pub fn geometrycollection_example_test() {
  let json_string =
    "
  {
    \"type\": \"GeometryCollection\",
    \"geometries\": [{
      \"type\": \"Point\",
      \"coordinates\": [100.0, 0.0]
    }, {
      \"type\": \"LineString\",
      \"coordinates\": [
        [101.0, 0.0],
        [102.0, 1.0]
      ]
    }]
  }
  "

  let decode_result =
    json.decode(from: json_string, using: gleojson.geojson_decoder)

  let decoded_geojson =
    decode_result
    |> should.be_ok

  let expected_geojson =
    gleojson.GeoJSONGeometry(
      gleojson.GeometryCollection([
        gleojson.Point([100.0, 0.0]),
        gleojson.LineString([[101.0, 0.0], [102.0, 1.0]]),
      ]),
    )

  decoded_geojson
  |> should.equal(expected_geojson)
}
