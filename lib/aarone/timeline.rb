require 'fileutils'

module Aarone
  class Timeline

    attr_accessor :root

    def initialize root
      @root = root
    end

    def clean!
      FileUtils.rm_rf(root)
    end

    # All this ImageMagick code is crap and would possibly be nicer if
    # written using RMagic or something else that's native to Ruby
    # http://rmagick.rubyforge.org/
    def generate_tumbnails!
      puts "generating timeline thumbnails"
      Dir.glob(root + '/**/*').select{|file| jpeg?(file) && file.include?("-full")}.each do |file|
        puts file
        directory = File.dirname(file)
        extension = File.extname(file)
        basename = File.basename(file, extension)

        full_square_image_filename = File.join(directory, basename.sub(/\-full/, '-sq') + extension)
        large_square_image_filename = File.join(directory, basename.sub(/\-full/, '@2x') + extension)
        small_square_image_filename = File.join(directory, basename.sub(/\-full/, '') + extension)

        crop_to_square(file, full_square_image_filename, min_dimension(file))
        scale_to_dimension(full_square_image_filename, large_square_image_filename, 350)
        scale_to_dimension(full_square_image_filename, small_square_image_filename, 175)
      end
    end

    private

    def jpeg? filename
      mime_type = `file -b --mime-type #{filename}`.chop
      mime_type == 'image/jpeg'
    end

    def min_dimension filename
      `identify #{filename}`.
        split[3].
        gsub( /(\d+)x(\d+).*/, '\1 \2').
        split.
        collect(&:to_i).
        min
    end

    def crop_to_square file, result_filename, dimension
      `convert -gravity Center -crop #{dimension}x#{dimension}+0+0 #{file} #{result_filename}`
    end

    def scale_to_dimension source_filename, result_filename, dimension      
      # use Acorn to scale images; only works on MacOS X
      output = `jstalk bin/scale.jstalk #{dimension} #{source_filename} #{result_filename}`
      raise "image scaling failed: #{output}" unless $?.exitstatus == 0
    end
  end
end
