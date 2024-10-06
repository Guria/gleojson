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

```gleam
import gleojson
import gleam/json
import gleam/option
import gleam/io

pub fn main() {
  // Create a Point geometry
  let point = gleojson.Point(gleojson.new_position_2d(lon: 125.6, lat: 10.1))

  // Create a Feature with the Point geometry
  let feature = gleojson.Feature(
    geometry: option.Some(point),
    properties: option.None,
    id: option.Some(gleojson.StringId("example-point"))
  )

  // Encode the Feature to GeoJSON
  let geojson = gleojson.GeoFeature(feature)
  let encoded = gleojson.encode_geojson(geojson, gleojson.properties_null_encoder)

  // Print the encoded GeoJSON
  io.println(json.to_string(encoded))
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
