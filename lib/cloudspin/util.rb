module Cloudspin
  class Util
    def self.full_path_from_local(relative_path)
      raw_path = self.raw_path_from_local(relative_path)
      if File.exists?(raw_path)
        Pathname.new(raw_path).realpath.to_s
      else
        relative_path
      end
    end

    def self.raw_path_from_local(relative_path)
      Dir.pwd + '/' + relative_path
    end
  end
end

