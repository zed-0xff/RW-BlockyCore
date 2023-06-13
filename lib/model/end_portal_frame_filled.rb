# frozen_string_literal: true

class Model
  class EndPortalFrameFilled < Model
    renders "block/end_portal_frame_filled"

    def render_top for_side
      dst = super
      tex = load_texture(textures['eye'])
      if for_side.north? || for_side.south?
        dst.copy_from tex, dst_y: 0, src_y: 4 # height: 8
        dst.copy_from tex, dst_y: 8, src_height: 4
      else
        dst.copy_from tex, dst_y: 8, src_height: 4
        tex = tex.rotated(-90)
        dst.copy_from tex, dst_y: 0, dst_x: 4, src_x: 4, src_y: 4
      end
      dst
    end

    def render_side *args, **kwargs
      kwargs[:elements] =  elements.filter{ |e| e.dig('faces', 'north', 'texture') != "#eye" }
      super *args, **kwargs
    end
  end
end
