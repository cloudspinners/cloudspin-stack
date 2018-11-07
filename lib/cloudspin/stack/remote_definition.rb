require 'net/http'
require 'zip'

module Cloudspin
  module Stack
    class RemoteDefinition

      def initialize(definition_location)
        @definition_location = definition_location
      end

      def self.is_remote?(definition_location)
        /^http.*\.zip$/.match definition_location
      end

      def fetch(local_folder)
        unpack(download_artefact(@definition_location), local_folder)
      end

      def download_artefact(artefact_url)
        download_dir = Dir.mktmpdir(['cloudspin-', '-download'])
        zipfile = "#{download_dir}/undetermined-spin-stack-artefact.zip"
        download_file(artefact_url, zipfile)
      end

      def download_file(remote_file, local_file)
        remote_file_uri = URI(remote_file)
        Net::HTTP.start(remote_file_uri.host, remote_file_uri.port) do |remote|
          response = remote.get(remote_file_uri)
          open(local_file, 'wb') do |local|
            local.write(response.body)
          end
        end
        local_file
      end

      def unpack(zipfile, where_to_put_it)
        folder_name = path_of_source_in(zipfile)
        # puts "DEBUG: Unzipping #{zipfile} to #{where_to_put_it}"
        clear_folder(where_to_put_it)
        Zip::File.open(zipfile) { |zip_file|
          zip_file.each { |f|
            # puts "-> #{f.name}"
            f_path = File.join(where_to_put_it, f.name)
            FileUtils.mkdir_p(File.dirname(f_path))
            # puts "DEBUG: Extracting #{f} to #{f_path}"
            zip_file.extract(f, f_path) unless File.exist?(f_path)
          }
        }
        raise MissingStackDefinitionConfigurationFileError unless File.exists? "#{where_to_put_it}/#{folder_name}/stack-definition.yaml"
        "#{where_to_put_it}/#{folder_name}/stack-definition.yaml"
      end

      def clear_folder(folder_to_clear)
        FileUtils.remove_entry_secure(folder_to_clear)
      end

      def path_of_source_in(zipfile_path)
        File.dirname(path_of_configuration_file_in(zipfile_path))
      end

      def path_of_configuration_file_in(zipfile_path)
        zipfile = Zip::File.open(zipfile_path)
        begin
          zipfile.entries.select { |entry|
            /^stack-definition.yaml$/.match entry.name
          }.first.name
        ensure
          zipfile.close
        end
      end

    end

    class MissingStackDefinitionConfigurationFileError < StandardError; end

  end
end

