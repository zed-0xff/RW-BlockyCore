require 'rimtool/rake_tasks'
load './lib/tasks/import.rake'

desc "render"
task :render, :model do |_, args|
  require_relative 'lib/model'
  require_relative 'lib/model_renderer'

  key = args.model
  key = "block/#{key}" unless key['block/']
  m = Model.find(key)

  r = ModelRenderer.new(m)
  %w'north south east west'.each do |side|
    img = r.render(Side[side])
    img.save(fname="#{side}.png")
    puts "[=] #{fname}"
  end
end

namespace :render do
  desc "render all sides"
  task :sides, :model do |_, args|
    require_relative 'lib/model'
    require_relative 'lib/model_renderer'

    key = args.model
    key = "block/#{key}" unless key['block/']
    m = Model.find(key)

    %w'up north south east west'.each do |side|
      img = m.render_side(Side[side]).scaled(4)
      img.save(fname="#{side}.png")
      puts "[=] #{fname}"
    end
  end
end

