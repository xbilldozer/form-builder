# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ksc-form_builder}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["William Alton"]
  s.date = %q{2011-01-05}
  s.description = %q{Basic app shell for KSC applications}
  s.email = %q{altonwi@gmail.com}
  s.extra_rdoc_files = [
    "README",
     "TODO"
  ]
  s.files = [
    "app/controllers/admin/form_fields_controller.rb",
     "app/controllers/admin/forms_controller.rb",
     "app/helpers/app_helper.rb",
     "app/helpers/field_helper.rb",
     "app/helpers/form_helper.rb",
     "app/helpers/group_helper.rb",
     "app/helpers/url_helper.rb",
     "app/models/field_type.rb",
     "app/models/field_validation.rb",
     "app/models/form.rb",
     "app/models/form_data.rb",
     "app/models/form_field.rb",
     "app/models/form_field_option.rb",
     "app/models/form_field_validation.rb",
     "app/models/form_version.rb",
     "app/models/form_group.rb",
     "app/models/prototype.rb",
     "app/views/admin/form_field_dependencies/_edit.html.haml",
     "app/views/admin/form_field_dependencies/_table.html.haml",
     "app/views/admin/form_field_dependencies/index.html.haml",
     "app/views/admin/form_field_options/_edit.html.haml",
     "app/views/admin/form_field_options/_table.html.haml",
     "app/views/admin/form_field_options/index.html.haml",
     "app/views/admin/form_field_validations/_edit.html.haml",
     "app/views/admin/form_field_validations/_table.html.haml",
     "app/views/admin/form_field_validations/index.html.haml",
     "app/views/admin/form_fields/_form.html.haml",
     "app/views/admin/form_fields/_menu.html.haml",
     "app/views/admin/form_fields/_table.html.haml",
     "app/views/admin/form_fields/dependencies.html.haml",
     "app/views/admin/form_fields/edit.html.haml",
     "app/views/admin/form_fields/index.html.haml",
     "app/views/admin/form_fields/new.html.haml",
     "app/views/admin/form_fields/options.html.haml",
     "app/views/admin/form_fields/validations.html.haml",
     "app/views/admin/forms/_form.html.haml",
     "app/views/admin/forms/_table.html.haml",
     "app/views/admin/forms/index.html.haml",
     "app/views/admin/forms/new.html.haml",
     "app/views/admin/forms/show.html.haml",
     "app/views/admin/form_groups/_table.html.haml",
     "app/views/admin/form_groups/new.html.haml",
     "app/views/admin/form_groups/edit.html.haml",
     "app/views/admin/form_groups/index.html.haml",
     "app/views/admin/form_groups/show.html.haml",
     "app/views/test/index.html.haml",
     "app/views/test/show.html.haml",
     "config/initializers/js_expansions.rb",
     "config/initializers/mongo_mapper.rb",
     "config/locales/en.yml",
     "config/menus/form_fields.yml",
     "config/menus/ksc.yml",
     "config/routes.rb",
     "lib/ksc-form_builder.rb",
     "lib/ksc-form_builder/nestable.rb"
  ]
  s.homepage = %q{http://the.killswitchcollective.com}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{private}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A versioned form builder with MongoDB backend}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mongo>, [">= 0"])
      s.add_runtime_dependency(%q<haml>, [">= 0"])
      s.add_runtime_dependency(%q<mini_magick>, [">= 0"])
      s.add_runtime_dependency(%q<bson_ext>, [">= 0"])
      s.add_runtime_dependency(%q<simple_form>, [">= 0"])
    else
      s.add_dependency(%q<mongo>, [">= 0"])
      s.add_dependency(%q<haml>, [">= 0"])
      s.add_dependency(%q<mini_magick>, [">= 0"])
      s.add_dependency(%q<bson_ext>, [">= 0"])
      s.add_dependency(%q<simple_form>, [">= 0"])
    end
  else
    s.add_dependency(%q<mongo>, [">= 0"])
    s.add_dependency(%q<haml>, [">= 0"])
    s.add_dependency(%q<mini_magick>, [">= 0"])
    s.add_dependency(%q<bson_ext>, [">= 0"])
    s.add_dependency(%q<simple_form>, [">= 0"])
  end
end
