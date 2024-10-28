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
