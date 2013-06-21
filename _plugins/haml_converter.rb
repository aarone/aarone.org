module Jekyll
  require 'haml'
  class HamlConverter < Converter
    safe true
    priority :low

    def matches(ext)
      ext =~ /haml/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content)
      engine = Haml::Engine.new(content)
      engine.render
    end
  end
end

module Haml::Filters
  module Scss
    include Base

    def render(text)
      ::Sass::Engine.new(text, ::Sass::Plugin.engine_options.merge(:syntax => :scss)).render
    end
  end
end
