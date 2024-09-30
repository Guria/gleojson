# gleojson

[![Package Version](https://img.shields.io/hexpm/v/gleojson)](https://hex.pm/packages/gleojson)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleojson/)

**gleojson** is a GeoJSON parsing and encoding library for Gleam, following the [RFC 7946](https://tools.ietf.org/html/rfc7946) specification. It provides types and utility functions to encode and decode GeoJSON objects such as Points, LineStrings, Polygons, and more.

**Note:** This package is currently in development and has not reached version 1.0.0 yet. The API is considered unstable and may undergo breaking changes in future releases. Please use with caution in production environments and expect potential updates that might require code changes.

## Installation

Add **gleojson** to your Gleam project:

```sh
gleam add gleojson
```

## Usage

```gleam
pub fn main() {
  let json_string = "{
    \"type\": \"Feature\",
    \"geometry\": {
    \"type\": \"Point\",
    \"coordinates\": [125.6, 10.1]
    },
    \"properties\": {
    \"name\": \"Dinagat Islands\"
    }
  }"
  // Decode the JSON string into a GeoJSON object
  let result = json.decode(from: json_string, using: gleojson.geojson_decoder)
  case result {
    Ok(geojson) -> {
      // Successfully decoded GeoJSON
    }
    Error(errors) -> {
      todo
      // Handle decoding errors
      // errors contains information about what went wrong during decoding
    }
  }

  // Construct GeoJSON from types
  let geojson = gleojson.GeoJSONFeatureCollection(
    gleojson.FeatureCollection([
      gleojson.Feature(
        geometry: option.Some(gleojson.Point([1.0, 2.0])),
        properties: option.None,
        id: option.Some(gleojson.StringId("feature-id")),
      ),
    ]),
  )

  // Encode to JSON string
  gleojson.encode_geojson(geojson) |> json.to_string
}
```

Further documentation can be found at https://hexdocs.pm/gleojson.

## Development

```
gleam build
gleam test
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) and [NOTICE](NOTICE) files for more details.
