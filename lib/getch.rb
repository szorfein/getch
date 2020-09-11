require_relative 'getch/options'

module Getch

  DEFAULT_OPTIONS = {
    language: 'en_US',
    location: 'US/Eastern',
    keyboard: 'us',
    disk: 'sda',
    fs: 'ext4',
    username: ''
  }

  def self.main(argv)
    options = Options.new(DEFAULT_OPTIONS, argv)
    puts "\nBuild Gentoo with the following args:\n"
    puts "lang: #{options.language}"
    puts "zoneinfo: #{options.zoneinfo}"
    puts "keyboard: #{options.keyboard}"
    puts "disk: #{options.disk}"
    puts "fs: #{options.fs}"
    puts "username: #{options.username}"
    puts
    print "Continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      puts "Right"
    else
      exit 1
    end
  end
end
