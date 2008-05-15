require "erb"
include ERB::Util

module ActionView
  class Base

    alias original_render_file render_file
        
    DEFAULT_AFTER_RENDER = lambda { | h |
      file = h[:template_path]
      locals = h[:locals]
      rendered_template = h[:rendered_template]
      parent_template = h[:parent_template_path]
      locals_text = ""
      locals.each_pair do |k, v|
        if v.kind_of?(ActiveRecord::Base)
          str = "#{v.class} (#{v.id})"
        elsif v.kind_of?(Array)
          array_str = v.map {|e| e.kind_of?(ActiveRecord::Base) ? e.class.to_s : e.to_s}.join(', ')
          str = "Array(#{array_str})"
        elsif v.kind_of?(Hash)
          hash_str = v.map {|a| 
            v = a[0].kind_of?(ActiveRecord::Base) ? a[1].class.to_s : a[1].to_s
            "#{a[0]}: #{v}" }.join(', ')
          str = "Hash(#{hash_str})"
        else
          str = "#{v.to_s} (#{v.class})"
        end
        locals_text += "<!-- .. #{k}: #{str.tr('<>', '_')} -->\n"
      end
      before_text = <<QUOTE
      <!-- Code generated from template: #{file}. -->
      <!-- Locals: -->
           #{locals_text}
QUOTE
      after_text = "\n<!-- end of #{file} -->\n"
      if parent_template
        after_text += "<!-- returning to #{parent_template} -->\n"
      end
      return before_text + rendered_template + after_text
    }

    def render_file(template_path, use_full_path = true, local_assigns = {})
      rendered_template = original_render_file(template_path, use_full_path, local_assigns)
      if defined?(AFTER_RENDER)
        parent_template_path = nil
        caller.detect {|e| 
          if p = (e.match(/\/app\/views\/([^.]*)\./) rescue nil)
            parent_template_path = p[1]
          end
        }
        h = {:template_path => template_path, :locals => local_assigns, 
             :rendered_template => rendered_template, :parent_template_path => parent_template_path}
        after_render_method.call(h)
      else
        rendered_template
      end
    end
    
    protected
    
    def after_render_method
      return AFTER_RENDER if (defined?(AFTER_RENDER) && AFTER_RENDER.kind_of?(Proc))
      return DEFAULT_AFTER_RENDER
    end
    
  end
end
