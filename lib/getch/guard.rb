class InvalidDisk < StandardError
end

class InvalidFormat < StandardError
end

module Getch::Guard
  def self.disk(name)
    raise InvalidDisk, "No disk." unless name
    raise InvalidDisk, "Bad device name #{name}." unless name.match(/^sd[a-z]{1}$/)
    raise InvalidDisk, "Disk /dev/#{name} no found." unless File.exist? "/dev/#{name}"
  rescue InvalidDisk => e
    puts "#{e.class} => #{e}"
    exit 1
  end

  def self.format(name)
    raise InvalidFormat, "No format specified." unless name
    raise InvalidFormat, "Format #{name} not yet available." if name.match(/btrfs/)
    raise InvalidFormat, "Format #{name} not supported." unless name.match(/zfs|lvm|zfs/)
  rescue InvalidFormat => e
    puts "#{e.class} => #{e}"
    exit 1
  end
end
