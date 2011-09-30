require "tilt"

module Machined
  class LayoutProcessor < Tilt::Template
    # A reference to the Sprockets context
    attr_reader :context
    
    # Path to the layout file
    attr_reader :layout_path
    
    def prepare
    end
    
    def evaluate(context, locals, &block)
      @context = context
      if layout? && @layout_path = resolve_layout
        context.depend_on @layout_path
        evaluate_layout
      else
        data
      end
    end
    
    protected
    
    def views
      context.machined.views
    end
    
    def layout?
      context.layout != false
    end
    
    def resolve_layout
      views.resolve "layouts/#{context.layout}", :content_type => context.content_type
    rescue Sprockets::FileNotFound, Sprockets::ContentTypeMismatch
      nil
    end
    
    # Recreate `Sprockets::Context#evaluate`, because it doesn't
    # support yielding. I'm not even sure it's necessary to
    # support multiple processors for a layout, though.
    def evaluate_layout
      processors = views.attributes_for(layout_path).processors
      result     = Sprockets::Utils.read_unicode layout_path
      
      processors.each do |processor|
        begin
          template = processor.new(layout_path.to_s) { result }
          result   = template.render(context, {}) { data }
        rescue Exception => e
          context.annotate_exception! e
          raise
        end
      end
      
      result
    end
  end
end
  