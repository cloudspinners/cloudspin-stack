module DefinitionHelpers

  def dummy_definition_specfile(spec_contents)
    temporary_yaml_file('stack-definition.yaml', spec_contents)
  end

  def temporary_yaml_file(filename, contents)
    file_path = "#{Dir.mktmpdir}/#{filename}"
    IO.write(file_path, contents)
    file_path
  end

  def dummy_definition_artefact
    build_artefact_file(create_dummy_artefact_path, <<~YAML_FILE
      ---
      stack:
        name: yaml_name
        version: 0.0.0-y
      YAML_FILE
    )
  end

  def create_dummy_artefact_path
    "#{Dir.mktmpdir('dummy_remote_files')}/dummy-definition.zip"
  end

  def build_artefact_file(artefact_name, definition_configuration)
    Zip::File.open(artefact_name, Zip::File::CREATE) do |zip|
      zip.get_output_stream('stack-definition.yaml') { |f|
        f.write(definition_configuration)
      }
    end
    artefact_name
  end

end
