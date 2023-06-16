# frozen_string_literal: true

module MC
  def self.asset_pathname *path
    CONFIG.asset_dirs.each do |d|
      [File.join(d, *path), File.join(d, "minecraft", *path)].each do |fname|
        return fname if File.exist?(fname)
      end
    end
  end

  def self.each_asset *path
    CONFIG.asset_dirs.each do |d|
      [File.join(d, *path), File.join(d, "minecraft", *path)].each do |p2|
        Dir[p2].each do |fname|
          yield fname
        end
      end
    end
  end
end
