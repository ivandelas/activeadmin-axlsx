Gem::Specification.new do |s|

  s.name = 'activeadmin-axlsx'
  s.version = '3.0.0'
  s.summary = 'This gem uses axlsx to provide excel/xlsx downloads for resources in Active Admin.'
  s.authors = 'Randy Morgan'
  s.add_runtime_dependency 'activeadmin', "> 0.6.0"
  s.add_runtime_dependency 'axlsx'

  s.required_ruby_version = '>= 1.9.2'
end
