require 'fileutils'

module Getch
  class Mount
    def initialize(disk, user)
      @disk = disk
      @user = user
      @root_dir = MOUNTPOINT
      @boot_dir = "#{@root_dir}/boot"
      @boot_efi_dir = "#{@root_dir}/boot/efi"
      @home_dir = @user ? "#{@root_dir}/home/#{@user}" : nil
      @state = Getch::States.new()
    end

    def run
      return if STATES[:mount]
      gen_vars
      mount_swap
      mount_root
      mount_boot
      mount_home
      mount_boot_efi if Helpers::efi?
      @state.mount
    end

    private

    def gen_vars
      @dev_boot_efi = nil
      @dev_boot = nil
      @dev_root = nil
      @dev_swap = nil
      @dev_home = nil
    end

    def mount_swap
      return if ! @dev_swap
      system("swapon #{@dev_swap}")
    end

    def mount_root
      return if ! @dev_root
      Dir.mkdir(@root_dir, 0700) if ! Dir.exist?(@root_dir)
      system("mount #{@dev_root} #{@root_dir}")
    end

    def mount_boot_efi
      return if ! @dev_boot_efi
      FileUtils.mkdir_p @boot_efi_dir, mode: 0700 if ! Dir.exist?(@boot_efi_dir)
      system("mount #{@dev_boot_efi} #{@boot_efi_dir}")
    end

    def mount_boot
      return if ! @dev_boot
      FileUtils.mkdir_p @boot_dir, mode: 0700 if ! Dir.exist?(@boot_dir)
      system("mount #{@dev_boot} #{@boot_dir}")
    end

    def mount_home
      return if ! @dev_home
      if @user != nil then
        FileUtils.mkdir_p @home_dir, mode: 0700 if ! Dir.exist?(@home_dir)
        system("mount #{@dev_home} #{@home_dir}")
      end
      @state.mount
    end

    def gen_fstab
      file = "#{@root_dir}/etc/fstab"
      FileUtils.mkdir_p file, mode: 0700 if ! Dir.exist?(file)
      gen_uuid
      datas = data_fstab
      File.write(file, datas.join("\n"))
    end

    def gen_uuid
      @uuid_swap = `lsblk -o "UUID" #{@dev_swap} | tail -1`.chomp() if @dev_swap
      @uuid_root = `lsblk -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
      @uuid_boot = `lsblk -o "UUID" #{@dev_boot} | tail -1`.chomp() if @dev_boot
      @uuid_boot_efi = `lsblk -o "UUID" #{@dev_boot_efi} | tail -1`.chomp() if @dev_boot_efi
      @uuid_home = `lsblk -o "UUID" #{@dev_home} | tail -1`.chomp() if @dev_home
    end

    def data_fstab
      return []
    end
  end
end
