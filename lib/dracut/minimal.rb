# frozen_string_litteral: true

module Dracut
  class Minimal < Root
    def get_line
      swap = Getch::Helpers.uuid @swap
      root = Getch::Helpers.uuid @root
      "root=UUID=#{root} rootfstype=#{@fs} resume=UUID=#{swap} rootflags=rw,relatime"
    end
  end
end
