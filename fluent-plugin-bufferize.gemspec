# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-bufferize"
  spec.version       = "0.0.2"
  spec.authors       = ["Masahiro Sano"]
  spec.email         = ["sabottenda@gmail.com"]
  spec.description   = %q{A fluentd plugin that enhances existing non-buffered output plugin as buffered plugin.}
  spec.summary       = %q{A fluentd plugin that enhances existing non-buffered output plugin as buffered plugin.}
  spec.homepage      = "https://github.com/sabottenda/fluent-plugin-bufferize"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd", "~> 0.14.0"
  spec.add_development_dependency "bundler", "> 1.3"
  spec.add_development_dependency "rake"
end
