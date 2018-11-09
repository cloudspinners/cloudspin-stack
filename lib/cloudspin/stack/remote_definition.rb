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

      def download_file(remote_file, local_file, tries = 0)
        raise "Too many redirects (#{remote_file})" if tries > 9
        remote_file_uri = URI(remote_file)

        Net::HTTP.start(
          remote_file_uri.host,
          remote_file_uri.port,
          :use_ssl => remote_file_uri.scheme == 'https'
        ) do |http|
          request = Net::HTTP::Get.new(remote_file_uri)
          http.request(request) do |response|
            case response
            when Net::HTTPSuccess     then write_local_file(response, local_file)
            when Net::HTTPRedirection then download_file(response['Location'], local_file, tries + 1)
            else
              raise "Request to '#{remote_file_uri}' failed: #{response.error} #{response.inspect}"
            end
          end
        end

        # puts "DEBUG: Downloaded file to #{local_file}"
        local_file
      end

      def write_local_file(response, local_file)
        open(local_file, 'wb') do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end

      def unpack(zipfile, where_to_put_it)
        folder_name = path_of_source_in(zipfile)
        # puts "DEBUG: Unzipping #{zipfile} to #{where_to_put_it}"
        clear_folder(where_to_put_it)
        Zip::File.open(zipfile) { |zip_file|
          zip_file.each { |f|
            f_path = File.join(where_to_put_it, f.name)
            FileUtils.mkdir_p(File.dirname(f_path))
            # puts "DEBUG: Extracting #{f} to #{f_path}"
            zip_file.extract(f, f_path) unless File.exist?(f_path)
          }
        }
        raise MissingStackDefinitionConfigurationFileError unless File.exists? "#{where_to_put_it}/#{folder_name}/stack-definition.yaml"
        "#{where_to_put_it}/#{folder_name}"
      end

      def clear_folder(folder_to_clear)
        FileUtils.remove_entry_secure(folder_to_clear)
      end

      def path_of_source_in(zipfile_path)
        File.dirname(path_of_configuration_file_in(zipfile_path))
      end

      def path_of_configuration_file_in(zipfile_path)
        zipfile = Zip::File.open(zipfile_path)
        list_of_files = begin
          zipfile.entries.select { |entry|
            /^stack-definition.yaml$/.match entry.name or /[\.\/]stack-definition.yaml$/.match entry.name
          }
        ensure
          zipfile.close
        end
        raise MissingStackDefinitionConfigurationFileError, "No configuration file in #{zipfile_path}" if list_of_files.empty?
        list_of_files.first.name
      end

    end

    class MissingStackDefinitionConfigurationFileError < StandardError; end

  end
end

