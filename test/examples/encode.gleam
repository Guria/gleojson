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
  |> gleojson.encode_geojson(gleojson.properties_null_encoder)
  |> json.to_string
}
