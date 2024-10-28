# gleojson

[![Package Version](https://img.shields.io/hexpm/v/gleojson)](https://hex.pm/packages/gleojson)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleojson/)

**gleojson** is a comprehensive GeoJSON parsing and encoding library for Gleam, following the [RFC 7946](https://tools.ietf.org/html/rfc7946) specification.

GeoJSON is a format for encoding a variety of geographic data structures.
It supports geometry types such as Point, LineString, Polygon, and others, as well as more complex types like Feature and FeatureCollection.
GeoJSON is widely used in mapping applications and geographic information systems (GIS).

**Note:** This package is currently in development and has not reached version 1.0.0 yet.
The API is considered unstable and may undergo breaking changes in future releases.
Please use with caution in production environments and expect potential updates that might require code changes.

## Features

- Full support for all GeoJSON object types: Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection, Feature, and FeatureCollection
- Flexible encoding and decoding of GeoJSON objects
- Custom property support for Feature and FeatureCollection objects
- Type-safe representation of GeoJSON structures

## Current Limitations

While **gleojson** aims to fully implement the GeoJSON specification (RFC 7946), some features are still under development. Key areas for future improvement include:

1. Coordinate validation
1. Antimeridian and pole handling
1. Bounding box support
1. Right-hand rule enforcement for polygon orientation
1. GeometryCollection usage recommendations

Despite these limitations, **gleojson** is fully functional for most common GeoJSON use cases.

## Installation

Add **gleojson** to your Gleam project:

```sh
gleam add gleojson
```

## Usage

Here's a basic example of how to use gleojson:

```gleam:./test/examples/encode.gleam
import gleam/json
import gleam/option
import gleojson

pub fn main() {
  // Create a Point geometry
  gleojson.Point(gleojson.new_position_2d(lon: 125.6, lat: 10.1))
  |> option.Some
  // Create a Feature with the Point geometry
  |> gleojson.Feature(
    properties: option.None,
    id: option.Some(gleojson.StringId("example-point")),
  )
  // Encode the Feature to GeoJSON
  |> gleojson.GeoFeature
  |> gleojson.encode_geojson(fn(_) { json.null() })
  |> json.to_string
}
```

Decoding GeoJSON objects is also straightforward:

```gleam:./test/examples/decode.gleam
import decode/zero
import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleojson

// Define custom properties type for your features
pub type ParkProperties {
  ParkProperties(
    name: String,
    area_sq_km: Float,
    year_established: Int,
    is_protected: Bool,
  )
}

// Define decoder for your custom properties
fn park_properties_decoder() {
  use name <- zero.field("name", zero.string)
  use area_sq_km <- zero.field("area_sq_km", zero.float)
  use year_established <- zero.field("year_established", zero.int)
  use is_protected <- zero.field("is_protected", zero.bool)
  ParkProperties(name:, area_sq_km:, year_established:, is_protected:)
  |> zero.success
}

pub fn main() {
  // Example GeoJSON string representing a national park
  let json_string =
    "{
    \"type\": \"Feature\",
    \"geometry\": {
      \"type\": \"Point\",
      \"coordinates\": [-119.5383, 37.8651]
    },
    \"properties\": {
      \"name\": \"Yosemite National Park\",
      \"area_sq_km\": 3029.87,
      \"year_established\": 1890,
      \"is_protected\": true
    },
    \"id\": \"yosemite\"
  }"

  // Decode the JSON string into a GeoJSON object
  let decoded =
    json.decode(
      from: json_string,
      using: zero.run(_, gleojson.geojson_decoder(park_properties_decoder())),
    )

  // Handle the decoded result
  case decoded {
    Ok(geojson) -> {
      case geojson {
        gleojson.GeoFeature(feature) -> {
          case feature.properties {
            option.Some(ParkProperties(name, area, year, is_protected)) -> {
              io.println(
                "Decoded " <> name <> ", established in " <> int.to_string(year),
              )
              io.println(
                "Area: "
                <> float.to_string(area)
                <> " sq km, Protected: "
                <> bool.to_string(is_protected),
              )
            }
            option.None -> io.println("Feature has no properties")
          }
        }
        _ -> io.println("Decoded a different type of GeoJSON object")
      }
    }
    Error(_error) -> io.println("Failed to decode")
  }
}
```

For more advanced usage, including custom properties and decoding, see the [documentation](https://hexdocs.pm/gleojson).

## Development

To build and test the project:

```sh
gleam build
gleam test
```

## Contributing

Contributions to gleojson are welcome! Please feel free to submit a Pull Request. Before contributing, please review our [contribution guidelines](CONTRIBUTING.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Please see the [NOTICE](NOTICE) file for information about third party components and the use of AI assistance in this project.