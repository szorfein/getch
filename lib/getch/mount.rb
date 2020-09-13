require 'fileutils'

module Getch
  class Mount
    def initialize(disk, user)
      @disk = disk
      @user = user
      @dest = MOUNTPOINT
      @boot_efi = MOUNTPOINT + '/boot/efi'
      @home = @user == nil ? MOUNTPOINT + '/home' : MOUNTPOINT + "/home/#{@user}"
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
        FileUtils.mkdir_p @boot_efi, mode: 0700 if ! Dir.exist?(@boot_efi)
        system("mount /dev/#{@disk}1 #{@boot_efi}")
      end
    end

    def home
      return if STATES[:mount]
      if @user != nil then
        FileUtils.mkdir_p @home, mode: 0700 if ! Dir.exist?(@home)
        system("mount /dev/#{@disk}4 #{@home}")
        FileUtils.chown @user, @user, @home
      end
      @state.mount
    end
  end
end
