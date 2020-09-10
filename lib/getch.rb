require_relative 'getch/options'

module Getch

  DEFAULT_OPTIONS = {
    language: 'en_US',
    location: 'Europe/Paris',
    keyboard: 'fr',
    disk: 'sda',
    fs: 'ext4',
    username: ''
  }

  def self.main(argv)
    puts "Starting..."
    options = Options.new(argv)
    puts options.zoneinfo
    puts DEFAULT_OPTIONS[:language]
    puts DEFAULT_OPTIONS[:location]
    puts DEFAULT_OPTIONS[:keyboard]
    puts DEFAULT_OPTIONS[:disk]
    puts DEFAULT_OPTIONS[:fs]
  end
end
