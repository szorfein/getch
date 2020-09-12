require "open-uri"

module Helpers
  def self.get_file_online(url, dest)
    URI.open(url) do |l|
      File.open(dest, "wb") do |f|
        f.write(l.read)
      end
    end
  end
end
