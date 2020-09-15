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
        #FileUtils.chown @user, @user, @home
      end
      @state.mount
    end

    def gen_fstab
      gen_uuid
      datas = gen_data
      File.write("#{MOUNTPOINT}/etc/fstab", datas.join("\n"), mode: "a")
    end

    private

    def gen_uuid
      @hdd1_uuid = `lsblk -o "UUID" /dev/#{@disk}1 | tail -1`.chomp()
      @hdd2_uuid = `lsblk -o "UUID" /dev/#{@disk}2 | tail -1`.chomp()
      @hdd3_uuid = `lsblk -o "UUID" /dev/#{@disk}3 | tail -1`.chomp()
      @hdd4_uuid = `lsblk -o "UUID" /dev/#{@disk}4 | tail -1`.chomp()
    end

    def gen_data
      boot = Helpers::efi? ? "UUID=#{@hdd1_uuid} /boot/efi vfat noauto,defaults  0 2" : ''
      swap = "UUID=#{@hdd2_uuid} none swap discard 0 0"
      root = "UUID=#{@hdd3_uuid} / ext4 defaults 0 1"
      home = @user != nil ? "UUID=#{@hdd4_uuid} /home/#{@user} ext4 defaults 0 2" : ''

      datas = [
        boot,
        swap,
        root,
        home
      ]
      return datas
    end
  end
end
