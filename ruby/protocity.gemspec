
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "protocity/version"

Gem::Specification.new do |spec|
  spec.name          = "protocity"
  spec.version       = Protocity::VERSION
  spec.authors       = ["Kyle Maxwell"]
  spec.email         = ["kyle@kylemaxwell.com"]

  spec.summary       = %q{Code generator for the Protocity data store}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/fizx/protocity"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.extensions   << "lib/vendor/grpc-swift/extconf.rb"
  spec.require_paths = ["lib"]
  
  spec.add_dependency "protobuf-core", "~> 3.5"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.post_install_message = <<-STR

  Protocity embeds a protoc compiler and a protoc-swift compiler.  If you are using 
  System Gems (i.e. you `sudo gem install`), you'll have to run protocity with sudo
  for the first time in order to fix permissions on these compilers.

STR
end
