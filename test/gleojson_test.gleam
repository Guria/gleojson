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

pub fn point_encode_decode_test() {
  let original_point = gleojson.Point([1.0, 2.0])

  let encoded_dynamic = gleojson.encode_point(original_point)

  let decoded_result = gleojson.point_decoder(encoded_dynamic)

  let decoded_point =
    decoded_result
    |> should.be_ok

  decoded_point
  |> should.equal(original_point)
}

pub fn multipoint_encode_decode_test() {
  let original_multipoint = gleojson.MultiPoint([[1.0, 2.0], [3.0, 4.0]])

  let encoded_dynamic = gleojson.encode_multipoint(original_multipoint)

  let decoded_result = gleojson.multipoint_decoder(encoded_dynamic)

  let decoded_multipoint =
    decoded_result
    |> should.be_ok

  decoded_multipoint
  |> should.equal(original_multipoint)
}

pub fn linestring_encode_decode_test() {
  let original_linestring = gleojson.LineString([[1.0, 2.0], [3.0, 4.0]])

  let encoded_dynamic = gleojson.encode_linestring(original_linestring)

  let decoded_result = gleojson.linestring_decoder(encoded_dynamic)

  let decoded_linestring =
    decoded_result
    |> should.be_ok

  decoded_linestring
  |> should.equal(original_linestring)
}

pub fn polygon_encode_decode_test() {
  let original_polygon =
    gleojson.Polygon([[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [1.0, 2.0]]])

  let encoded_dynamic = gleojson.encode_polygon(original_polygon)

  let decoded_result = gleojson.polygon_decoder(encoded_dynamic)

  let decoded_polygon =
    decoded_result
    |> should.be_ok

  decoded_polygon
  |> should.equal(original_polygon)
}

pub fn multipolygon_encode_decode_test() {
  let original_multipolygon =
    gleojson.MultiPolygon([
      [[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [1.0, 2.0]]],
      [[[7.0, 8.0], [9.0, 10.0], [11.0, 12.0], [7.0, 8.0]]],
    ])

  let encoded_dynamic = gleojson.encode_multipolygon(original_multipolygon)

  let decoded_result = gleojson.multipolygon_decoder(encoded_dynamic)

  let decoded_multipolygon =
    decoded_result
    |> should.be_ok

  decoded_multipolygon
  |> should.equal(original_multipolygon)
}

pub fn geometrycollection_encode_decode_test() {
  let point = gleojson.Point([1.0, 2.0])
  let linestring = gleojson.LineString([[3.0, 4.0], [5.0, 6.0]])

  let original_geometrycollection =
    gleojson.GeometryCollection([
      gleojson.GeometryPoint(point),
      gleojson.GeometryLineString(linestring),
    ])

  let encoded_dynamic =
    gleojson.encode_geometrycollection(original_geometrycollection)

  let decoded_result = gleojson.geometrycollection_decoder(encoded_dynamic)

  let decoded_geometrycollection =
    decoded_result
    |> should.be_ok

  decoded_geometrycollection
  |> should.equal(original_geometrycollection)
}

pub fn feature_encode_decode_test() {
  let point = gleojson.Point([1.0, 2.0])

  let properties =
    dict.from_list([
      #("name", dynamic.from("Test Point")),
      #("value", dynamic.from(42)),
    ])

  let original_feature =
    gleojson.Feature(
      geometry: option.Some(gleojson.GeometryPoint(point)),
      properties: option.Some(properties),
      id: option.Some(gleojson.StringId("feature-id")),
    )

  let encoded_dynamic = gleojson.encode_feature(original_feature)

  let decoded_result = gleojson.feature_decoder(encoded_dynamic)

  let decoded_feature =
    decoded_result
    |> should.be_ok

  decoded_feature
  |> should.equal(original_feature)
}

pub fn featurecollection_encode_decode_test() {
  let point = gleojson.Point([1.0, 2.0])

  let properties =
    dict.from_list([
      #("name", dynamic.from("Test Point")),
      #("value", dynamic.from(42)),
    ])

  let feature =
    gleojson.Feature(
      geometry: option.Some(gleojson.GeometryPoint(point)),
      properties: option.Some(properties),
      id: option.Some(gleojson.StringId("feature-id")),
    )

  let original_featurecollection = gleojson.FeatureCollection([feature])

  let encoded_dynamic =
    gleojson.encode_featurecollection(original_featurecollection)

  let decoded_result = gleojson.featurecollection_decoder(encoded_dynamic)

  let decoded_featurecollection =
    decoded_result
    |> should.be_ok

  decoded_featurecollection
  |> should.equal(original_featurecollection)
}

pub fn gleojson_encode_decode_test() {
  let point = gleojson.Point([1.0, 2.0])
  let geometry = gleojson.GeometryPoint(point)

  let original_geojson = gleojson.GeoJSONGeometry(geometry)

  let encoded_dynamic = gleojson.encode_geojson(original_geojson)

  let decoded_result = gleojson.geojson_decoder(encoded_dynamic)

  let decoded_geojson =
    decoded_result
    |> should.be_ok

  decoded_geojson
  |> should.equal(original_geojson)
}

pub fn invalid_type_decode_test() {
  let invalid_dynamic =
    dynamic.from(
      dict.from_list([
        #("type", dynamic.from("InvalidType")),
        #("coordinates", dynamic.from([1.0, 2.0])),
      ]),
    )

  let decoded_result = gleojson.geometry_decoder(invalid_dynamic)

  decoded_result
  |> should.be_error
}

pub fn invalid_coordinates_decode_test() {
  let invalid_dynamic =
    dynamic.from(
      dict.from_list([
        #("type", dynamic.from("Point")),
        #("coordinates", dynamic.from("invalid coordinates")),
      ]),
    )

  let decoded_result = gleojson.point_decoder(invalid_dynamic)

  decoded_result
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
      geometry: option.Some(
        gleojson.GeometryPoint(gleojson.Point([102.0, 0.5])),
      ),
      properties: option.Some(
        dict.from_list([#("prop0", dynamic.from("value0"))]),
      ),
      id: option.None,
    )

  let linestring_feature =
    gleojson.Feature(
      geometry: option.Some(
        gleojson.GeometryLineString(
          gleojson.LineString([
            [102.0, 0.0],
            [103.0, 1.0],
            [104.0, 0.0],
            [105.0, 1.0],
          ]),
        ),
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
        gleojson.GeometryPolygon(
          gleojson.Polygon([
            [
              [100.0, 0.0],
              [101.0, 0.0],
              [101.0, 1.0],
              [100.0, 1.0],
              [100.0, 0.0],
            ],
          ]),
        ),
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

  let expected_geojson =
    gleojson.GeoJSONGeometry(
      gleojson.GeometryPoint(gleojson.Point([100.0, 0.0])),
    )

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
    gleojson.GeoJSONGeometry(
      gleojson.GeometryLineString(
        gleojson.LineString([[100.0, 0.0], [101.0, 1.0]]),
      ),
    )

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
      gleojson.GeometryPolygon(
        gleojson.Polygon([
          [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
        ]),
      ),
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
      gleojson.GeometryPolygon(
        gleojson.Polygon([
          [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
          [[100.8, 0.8], [100.8, 0.2], [100.2, 0.2], [100.2, 0.8], [100.8, 0.8]],
        ]),
      ),
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
    gleojson.GeoJSONGeometry(
      gleojson.GeometryMultiPoint(
        gleojson.MultiPoint([[100.0, 0.0], [101.0, 1.0]]),
      ),
    )

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
      gleojson.GeometryMultiLineString(
        gleojson.MultiLineString([
          [[100.0, 0.0], [101.0, 1.0]],
          [[102.0, 2.0], [103.0, 3.0]],
        ]),
      ),
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
      gleojson.GeometryMultiPolygon(
        gleojson.MultiPolygon([
          [
            [
              [102.0, 2.0],
              [103.0, 2.0],
              [103.0, 3.0],
              [102.0, 3.0],
              [102.0, 2.0],
            ],
          ],
          [
            [
              [100.0, 0.0],
              [101.0, 0.0],
              [101.0, 1.0],
              [100.0, 1.0],
              [100.0, 0.0],
            ],
            [
              [100.2, 0.2],
              [100.2, 0.8],
              [100.8, 0.8],
              [100.8, 0.2],
              [100.2, 0.2],
            ],
          ],
        ]),
      ),
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
      gleojson.GeometryGeometryCollection(
        gleojson.GeometryCollection([
          gleojson.GeometryPoint(gleojson.Point([100.0, 0.0])),
          gleojson.GeometryLineString(
            gleojson.LineString([[101.0, 0.0], [102.0, 1.0]]),
          ),
        ]),
      ),
    )

  decoded_geojson
  |> should.equal(expected_geojson)
}
