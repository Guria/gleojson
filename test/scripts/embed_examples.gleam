import argv
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  process_args(argv.load())
}

fn process_args(args: argv.Argv) {
  case args.arguments {
    ["--check", filename] -> process_file(filename, True)
    [filename] -> process_file(filename, False)
    _ -> print_usage()
  }
}

fn print_usage() {
  io.println("Usage: [--check] <filename>")
  io.println("  --check    Check only mode (don't modify the file)")
  io.println("  <filename> The markdown file to process")
}

fn process_file(filename: String, check_only: Bool) {
  case simplifile.read(filename) {
    Ok(content) -> {
      let processed = process_content(content)
      case check_only {
        True -> compare_content(content, processed)
        False -> update_file(filename, content, processed)
      }
    }
    Error(error) -> io.println("Error reading file: " <> string.inspect(error))
  }
}

type CodeBlockState {
  NotInBlock
  InRegularBlock
  InAnnotatedBlock(filename: String)
}

type ProcessState {
  ProcessState(output: String, code_block_state: CodeBlockState, buffer: String)
}

fn process_content(content: String) -> String {
  content
  |> string.split("\n")
  |> list.fold(ProcessState("", NotInBlock, ""), fn(state, line) {
    process_line(state, line)
  })
  |> fn(state) { state.output <> state.buffer }
  |> string.trim
}

fn process_line(state: ProcessState, line: String) -> ProcessState {
  case state.code_block_state, line {
    NotInBlock, "```" <> rest -> {
      case string.split(rest, ":") {
        [lang, filepath] -> {
          let trimmed_filepath = string.trim(filepath)
          ProcessState(
            state.output <> "```" <> lang <> ":" <> filepath <> "\n",
            InAnnotatedBlock(trimmed_filepath),
            "",
          )
        }
        _ -> ProcessState(state.output <> line <> "\n", InRegularBlock, "")
      }
    }
    InRegularBlock, "```" ->
      ProcessState(state.output <> state.buffer <> "```\n", NotInBlock, "")
    InRegularBlock, _ ->
      ProcessState(state.output, InRegularBlock, state.buffer <> line <> "\n")
    InAnnotatedBlock(filename), "```" -> {
      case simplifile.read(filename) {
        Ok(file_content) ->
          ProcessState(
            state.output <> string.trim(file_content) <> "\n```\n",
            NotInBlock,
            "",
          )
        Error(_) ->
          ProcessState(
            state.output <> "File not found: " <> filename <> "\n```\n",
            NotInBlock,
            "",
          )
      }
    }
    InAnnotatedBlock(_), _ -> state
    NotInBlock, _ -> ProcessState(state.output <> line <> "\n", NotInBlock, "")
  }
}

fn compare_content(original: String, processed: String) {
  case original == processed {
    True -> io.println("No changes detected.")
    False -> {
      io.println("Changes detected.")
      exit(1)
    }
  }
}

fn update_file(filename: String, original: String, processed: String) {
  case original == processed {
    True -> io.println("No changes needed in '" <> filename <> "'.")
    False -> {
      case simplifile.write(filename, processed) {
        Ok(_) -> io.println("Processed and updated '" <> filename <> "'.")
        Error(error) ->
          io.println("Error writing file: " <> string.inspect(error))
      }
    }
  }
}

@external(erlang, "erlang", "halt")
fn exit(status: Int) -> Nil
