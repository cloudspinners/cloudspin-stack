module Cloudspin
  class Util
    def self.full_path_to(relative_path)
      Pathname.new(Dir.pwd + '/' + relative_path).realpath.to_s
    end
  end
end

