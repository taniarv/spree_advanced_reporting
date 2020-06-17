Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_advanced_reporting'
  s.version     = '2.1.1'
  s.summary     = 'Advanced Reporting for Spree'
  s.author	= "Steph Skardal, Tania Rubio"
  s.email	= "steph@endpoint.com, taniarubiov@gmail.com"
  s.required_ruby_version = '>= 1.8.7'
  #s.description = 'Advanced Add (optional) gem description here'
  # s.rubyforge_project = 'actionmailer'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = true

  s.add_dependency('spree_core', '>= 0.80.0.beta')
  s.add_dependency('ruport', '>= 1.6.3')
  s.add_dependency('ruport-util') #, :lib => 'ruport/util')
end
