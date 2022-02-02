# frozen_string_litteral: true

module Dracut
  class Minimal
    def get_line
      swap = get_uuid @swap
      root = get_uuid @root
      "root=UUID=#{root} rootfstype=#{@fs} resume=UUID=#{swap} rootflags=rw,relatime"
    end
  end
end
