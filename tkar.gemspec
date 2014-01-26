require 'tkar/version'

Gem::Specification.new do |s|
  s.name = "tkar"
  s.version = Tkar::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0")
  s.authors = ["Joel VanderWerf"]
  s.date = Time.now.strftime "%Y-%m-%d"
  s.summary = "Generic 2D animation tool"
  s.description = "Tkar listens to an incoming stream of data and animates it in a 2D canvas. User interaction is streamed back out."
  s.email = "vjoel@users.sourceforge.net"
  s.extra_rdoc_files = ["README.md", "COPYING"]
  s.files = Dir[
    "README.md", "COPYING", "Rakefile",
    "doc/**/*",
    "bin/**/*.rb",
    "lib/**/*.rb",
    "examples/**/*",
    "test/**/*.rb"
  ]
  s.test_files = Dir["test/*.rb"]
  s.homepage = "https://github.com/vjoel/tkar"
  s.license = "BSD"
  s.rdoc_options = [
    "--quiet", "--line-numbers", "--inline-source",
    "--title", "Tkar", "--main", "README.md"]
  s.require_paths = ["lib"]
end
