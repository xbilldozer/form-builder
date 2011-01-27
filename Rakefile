require 'rake'

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "ksc-form_builder"
    gem.author = "William Alton"
    gem.email = "altonwi@gmail.com"
    gem.homepage = "http://the.killswitchcollective.com"
    gem.summary = "A versioned form builder with MongoDB backend"
    gem.rubyforge_project = 'private'
    gem.description = "Basic app shell for KSC applications"
    gem.files = Dir["{lib}/**/*", "{app}/**/*", "{config}/**/*"]
    gem.test_files = []
    gem.add_dependency("mongo")
    gem.add_dependency("haml")
    gem.add_dependency("mini_magick")
    gem.add_dependency("bson_ext")
    gem.add_dependency("simple_form")
  end
  
  FileList['lib/tasks/**/*.rake'].each { |task| import task }
rescue
  puts "Jeweler or one of its dependencies is not installed."
end


