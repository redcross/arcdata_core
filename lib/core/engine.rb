module Core
  class Engine < ::Rails::Engine
    initializer 'activeservice.autoload', :before => :set_autoload_paths do |app|
      app.config.autoload_paths += [File.expand_path("#{config.root}/lib")]
      app.config.paths["db/migrate"] << "#{config.root}/db/migrate"
    end

    initializer "activeadmin" do
      if defined?(ActiveAdmin)
        ActiveAdmin.application.load_paths.unshift "#{config.root}/app/admin"
      end
    end
  end
end
