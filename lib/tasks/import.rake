require 'digest/md5'
require 'set'

ASSETS_DIR = File.expand_path("~/games/minecraft/assets")

def dedup_dir! dirname
  h = Hash.new{ |k,v| k[v] = [] }
  entity_files = Hash.new{ |k,v| k[v] = [] }
  deletable_files = Set.new

  Dir[File.join(dirname, "*.png")].each do |fname|
    md5 = Digest::MD5.file(fname).hexdigest
    h[md5] << fname
    entity_name = fname.split(/[._]/).first
    entity_files[entity_name] << fname
  end
  h.each do |md5, fnames|
    next if fnames.size < 2
    #printf "[.] %2d  %s\n", fnames.size, md5
    deletable_files += fnames.sort_by(&:size)[1..-1].to_set
  end
  entity_files.each do |entity_name, fnames|
    if fnames.all?{ |fn| deletable_files.include?(fn) }
      puts "[*] deleting #{entity_name} .."
      fnames.each do |fn|
        File.unlink(fn)
      end
    end
  end
end

desc "import all"
task :import => "import:all"

namespace :import do
  task :all => [:prune, :models, :doors, :dedup, :defs]

  desc "clear all imported data"
  task :prune do
    system "rm -rf Textures/Blocky/?"
  end

  desc "delete duplicate entities"
  task :dedup do
    Dir["Textures/Blocky/?"].sort.each do |dirname|
      dedup_dir! dirname
    end
  end

  desc "import models"
  task :models do
    require_relative "../model_parser"
    ModelParser.new(ASSETS_DIR).process!
  end

  desc "import doors"
  task :doors do
    require_relative "../door_maker"
    DoorMaker.new(ASSETS_DIR).process!
  end

  desc "make defs"
  task :defs do
    require_relative "../def_maker"
    DefMaker.new.process!
  end
end
