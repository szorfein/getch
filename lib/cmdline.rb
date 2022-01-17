module CmdLine
  def echo(path, content, mode = 0700)
    f = File.new path, 'w'
    f.write "#{content}\n"
    f.chmod mode
    f.close
  end

  class Kernel
    include CmdLine

    def initialize(arg)
      @dir = arg[:workdir]
      @file = "#{@dir}/90_cmdline.config"
      @line = ''
    end

    def main
      puts ' > Generate cmdline for Kernel...'
      cpu_mitigations
      distrust_cpu
      kernel_hardening
      quiet

      puts " >> Writing cmdline to #{@file}..."
      echo @file, "CONFIG_CMDLINE_BOOL=y\nCONFIG_CMDLINE=\"#{@line}\"\n", 0644
    end

    private

    def cpu_mitigations
      @line << 'mds=full,nosmt'
      @line << ' l1tf=full,force'
      @line << ' kvm.nx_huge_pages=force'
    end

    def distrust_cpu
      @line << ' random.trust_cpu=off'
    end

    def kernel_hardening
      @line << ' slab_nomerge'
      @line << ' slub_debug=FZ'
      @line << ' init_on_alloc=1 init_on_free=1'
      @line << ' mce=0'
      @line << ' pti=on'
      @line << ' vsyscall=none'
      @line << ' page_alloc.shuffle=1'
      @line << ' debugfs=off'
    end

    def quiet
      @line << ' quiet loglevel=0'
    end
  end

  class Grub
    include CmdLine

    def initialize(arg)
      @conf = arg[:workdir]
      @default_alias = 'GRUB_CMDLINE_LINUX_DEFAULT'
      @cmd_alias = 'GRUB_CMDLINE_LINUX'
    end

    def main
      puts ' > Generate cmdline for Grub...'
      cpu_mitigations
      distrust_cpu
      kernel_hardening
      quiet
    end

    private

    def cpu_mitigations
      lines = []
      lines << add_linux('mds=full,nosmt')
      lines << add_linux('l1tf=full,force')
      lines << add_linux('kvm.nx_huge_pages=force')

      puts " >> Writing to #{@conf}/40_cpu_mitigations.cfg"
      echo "#{@conf}/40_cpu_mitigations.cfg", lines.join("\n"), 0755
    end

    def distrust_cpu
      lines = []
      lines << add_linux('random.trust_cpu=off')

      puts " >> Writing to #{@conf}/40_distrust_cpu.cfg"
      echo "#{@conf}/40_distrust_cpu.cfg", lines.join("\n"), 0755
    end

    def kernel_hardening
      lines = []
      lines << add_linux('slab_nomerge')
      lines << add_linux('slub_debug=FZ')
      lines << add_linux('init_on_alloc=1 init_on_free=1')
      lines << add_linux('mce=0')
      lines << add_linux('pti=on')
      lines << add_linux('vsyscall=none')
      lines << add_linux('page_alloc.shuffle=1')
      lines << add_linux('debugfs=off')

      puts " >> Writing to #{@conf}/40_kernel_hardening.cfg"
      echo "#{@conf}/40_kernel_hardening.cfg", lines.join("\n"), 0755
    end

    def quiet
      lines = []
      lines << "#{@default_alias}=\"$(echo \"$#{@default_alias}\" | LANG=C str_replace \"quiet\" \"\")\""
      lines << add_linux_default('quiet loglevel=0')

      puts " >> Writing to #{@conf}/41_quiet.cfg"
      echo "#{@conf}/41_quiet.cfg", lines.join("\n"), 0755
    end

    def add_linux(arg)
      "#{@cmd_alias}=\"$#{@cmd_alias} #{arg}\""
    end

    def add_linux_default(arg)
      "#{@default_alias}=\"$#{@default_alias} #{arg}\""
    end
  end
end
