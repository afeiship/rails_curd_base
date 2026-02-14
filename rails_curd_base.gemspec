require_relative "lib/rails_curd_base/version"

Gem::Specification.new do |spec|
  spec.name        = "rails_curd_base"
  spec.version     = RailsCurdBase::VERSION
  spec.authors     = ["aric.zheng"]
  spec.email       = ["1290657123@qq.com"]
  spec.homepage    = "https://github.com/aferic/rails_curd_base"
  spec.summary     = "A Rails CRUD base controller with query capabilities, pagination, sorting, searching, and filtering"
  spec.description  = <<~DESC
    RailsCurdBase provides a ready-to-use CRUD base controller for Ruby on Rails API applications.
    It offers zero-configuration CRUD operations, powerful query capabilities (pagination, sorting,
    searching, filtering), unified JSON response format via RailsWarp, and flexible lifecycle hooks.
    Perfect for building RESTful APIs quickly with Rails 6.0+.
  DESC

  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aferic/rails_curd_base"
  spec.metadata["changelog_uri"] = "https://github.com/aferic/rails_curd_base/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/aferic/rails_curd_base/issues"
  spec.metadata["documentation_uri"] = "https://github.com/aferic/rails_curd_base/blob/main/README.md"
  spec.metadata["wiki_uri"] = "https://github.com/aferic/rails_curd_base/wiki"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "llms.txt"]
  end

  spec.required_ruby_version = ">= 2.7.0"

  # Runtime dependencies
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "kaminari", ">= 0.16"
  spec.add_dependency "rails_warp", ">= 0.1.0"
end
