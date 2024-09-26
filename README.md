# gleojson

[![Package Version](https://img.shields.io/hexpm/v/gleojson)](https://hex.pm/packages/gleojson)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleojson/)

**gleojson** is a GeoJSON parsing and encoding library for Gleam, following the [RFC 7946](https://tools.ietf.org/html/rfc7946) specification. It provides types and utility functions to encode and decode GeoJSON objects such as Points, LineStrings, Polygons, and more.

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
      let encoded = gleojson.encode_geojson(geojson)
      // encoded is now a Dynamic representation of the GeoJSON object
      // You can use it for further processing or encoding back to JSON
    }
    Error(errors) -> {
      todo
      // Handle decoding errors
      // errors contains information about what went wrong during decoding
    }
  }
}
```

Further documentation can be found at https://hexdocs.pm/gleojson.

## Development

```
gleam build
gleam test
```
