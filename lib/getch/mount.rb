module Getch
  class Mount
    def initialize(disk, user)
      @disk = disk
      @user = user
      @dest = '/mnt/gentoo'
      @state = Getch::States.new()
    end

    def swap
      return if STATES[:mount]
      system("swapon /dev/#{@disk}2")
    end

    def root
      return if STATES[:mount]
      Dir.mkdir(@dest, 0700) if ! Dir.exist?(@dest)
      system("mount /dev/#{@disk}3 #{@dest}") 
    end

    def boot
      return if STATES[:mount]
      if Helpers::efi? then
        Dir.mkdir(@dest + '/boot', 0700) if ! Dir.exist?(@dest + '/boot')
        Dir.mkdir(@dest + '/boot/efi', 0700) if ! Dir.exist?(@dest + '/boot/efi')
        system("mount /dev/#{@disk}1 #{@dest}/boot/efi") 
      end
    end

    def home
      return if STATES[:mount]
      Dir.mkdir(@dest + '/home', 0700) if ! Dir.exist?(@dest + '/home')
      if @user != nil then
        Dir.mkdir(@dest + "/home/#{@user}", 0700) if ! Dir.exist?(@dest + "/home/#{@user}")
        system("mount /dev/#{@disk}4 #{@dest}/home/#{@user}") 
      end
      @state.mount
    end
  end
end
