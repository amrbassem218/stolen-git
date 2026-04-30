Gem::Specification.new do |spec|
  spec.name          = 'stg'
  spec.version       = '0.1.1'
  spec.authors       = ['Amr ElTaweel']
  spec.email         = ['amrbeducation@gmail.com']

  spec.summary       = 'Stg is like git but worse.'
  spec.description   = "Stg is a version control system built on an architecture inspired by git's but in the great language of ruby"
  spec.homepage      = 'https://github.com/amrbassem218/stolen-git'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb', 'bin/*', 'README.md', 'LICENSE.txt']

  spec.bindir        = 'bin'
  spec.executables   = ['stg']

  spec.require_paths = ['lib']

  # If your tool needs other gems to work, add them here:
  spec.add_dependency 'colorize', '~> 1.1'
end
