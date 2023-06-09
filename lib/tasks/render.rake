desc "render"
task :render, :model do |_, args|
  require_relative '../model'
  require_relative '../model_renderer'

  key = args.model
  key = "block/#{key}" unless key['/']
  m = Model.find(key)

  unless m.render_types
    r = ModelRenderer.new(m, '')
    r.detect_render_type 
  end

  m.render_types.each do |suffix, rtype|
    r = ModelRenderer.new(m, suffix)
    Side.each_nsew do |side|
      img = r.render(side)
      img.save(fname="#{suffix}_#{side}.png")
      puts "[=] #{fname}"
    end
  end
end

namespace :render do
  desc "render all sides"
  task :sides, :model do |_, args|
    require_relative '../model'
    require_relative '../model_renderer'

    key = args.model
    key = "block/#{key}" unless key['block/']
    m = Model.find(key)

    Side.each do |side|
      img = m.render_side(side).scaled(4)
      img.save(fname="#{side}.png")
      puts "[=] #{fname}"
    end
  end
end

