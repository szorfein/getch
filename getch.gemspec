require File.dirname(__FILE__) + "/lib/getch/version"

Gem::Specification.new do |s|
  s.name = "getch"
  s.version = Getch::VERSION
  s.summary = "A CLI tool to install Gentoo"
  s.authors = ["szorfein"]
  s.email = ["szorfein@protonmail.com"]
  s.homepage = 'https://github.com/szorfein/getch'
  s.license = "MIT"
  s.required_ruby_version = '>=2.5'

  s.files = `git ls-files`.split(" ")
  s.files.reject! { |fn| fn.include? "certs" }

  s.executables = [ 'getch' ]

  s.cert_chain  = ['certs/szorfein.pem']
  s.signing_key = File.expand_path("~/.ssh/gem-private_key.pem") if $0 =~ /gem\z/
end
