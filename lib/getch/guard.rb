class InvalidDisk < StandardError
end

class InvalidFormat < StandardError
end

class InvalidZone < StandardError
end

class InvalidKeymap < StandardError
end

module Getch::Guard
  def self.disk(name)
    raise InvalidDisk, "No disk." unless name
    raise InvalidDisk, "Bad device name #{name}." unless name.match(/^sd[a-z]{1}$/)
    raise InvalidDisk, "Disk /dev/#{name} no found." unless File.exist? "/dev/#{name}"
    name
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

  def self.zone(name)
    raise InvalidZone, "No zoneinfo specified." unless name
    raise InvalidZone, "Directory /usr/share/zoneinfo/ no found on this system..." unless Dir.exist? "/usr/share/zoneinfo/"
    raise InvalidZone, "Zoneinfo #{name} is no found in /usr/share/zoneinfo/." unless File.exist? "/usr/share/zoneinfo/#{name}"
  rescue InvalidZone => e
    puts "#{e.class} => #{e}"
    exit 1
  end

  def self.keymap(name)
    raise InvalidKeymap, "No keymap specified." unless name
    key = []

    if Dir.exist? '/usr/share/keymaps'
      key = Dir.glob("/usr/share/keymaps/**/#{name}.map.gz")
    elsif Dir.exist? '/usr/share/kbd/keymaps'
      key = Dir.glob("/usr/share/kbd/keymaps/**/#{name}.map.gz")
    else
      raise InvalidKeymap, "No directory found for keymap."
    end

    if key == []
      raise InvalidKeymap, "Keymap #{name} no found."
    end
    name
  rescue InvalidKeymap => e
    puts "#{e.class} => #{e}"
    exit 1
  end
end
