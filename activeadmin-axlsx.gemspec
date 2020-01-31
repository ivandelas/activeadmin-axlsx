require File.expand_path('../lib/active_admin/axlsx/version', __FILE__)

Gem::Specification.new do |s|

  s.name = 'activeadmin-axlsx'
  s.version = '3.2.0'
  s.summary = 'This gem uses axlsx to provide excel/xlsx downloads for resources in Active Admin.'
  s.authors = 'Randy Morgan, Todd Hambley'
  s.platform = Gem::Platform::RUBY
  s.add_runtime_dependency 'activeadmin', '>= 0.6.6', '< 2'
  s.add_runtime_dependency 'axlsx', '~> 2.0'

  s.required_ruby_version = '>= 2.3.4'
  s.require_path = 'lib'
end
