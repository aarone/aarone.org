require 'aws-sdk'
require 'fileutils'
require 'stringio'
require 'tempfile'
require 'time'
require 'uri'
require 'yaml'
require 'zlib'

module Aarone
  class Website

    attr_reader :root, :bucket, :cloudfront, :cloudfront_distribution_id

    def initialize jekyll_root, bucket, cloudfront = AWS::CloudFront.new, distribution_id
      @root = jekyll_root
      @bucket = bucket
      @cloudfront = cloudfront
      @cloudfront_distribution_id = distribution_id
    end

    def site_directory
      # trailing slash is expected below when key names are calculated
      File.join(root, '_site/')
    end

    def clean!
      FileUtils.rm_rf(site_directory)
    end

    def generate!
      output = `cd #{root} && jekyll build`
      raise "jekyll failed: #{output}" unless $?.exitstatus == 0
    end

    # uploads files to S3 and invalidates CloudFront caches
    def publish! pattern = '**/*'
      keys = upload_to_s3! pattern
      invalidate_cloudfront_distribution!(keys)
    end

    def upload_to_s3! pattern
      keys = []
      puts "uploading website to S3"
      Dir.glob(File.join(site_directory, pattern)).each do |file|
        key = file[site_directory.length..-1]
        path = File.expand_path(file)
        next if File.directory?(path)

        keys += upload_file(bucket, key, path, upload_options(path))
      end
      keys
    end

    def invalidate_cloudfront_distribution! keys
      puts "invalidating CloudFront caches: keys: #{keys.inspect}"
      cloudfront.client.create_invalidation(:distribution_id => cloudfront_distribution_id,
                                            :invalidation_batch => {
                                              :paths => {
                                                :quantity => keys.length,
                                                :items => keys.collect{|key| URI.encode('/' + key)}
                                              },
                                              :caller_reference => Time.now.utc.iso8601
                                            }
                                            )

    end

    private

    # cache for a day by default
    def upload_options file, max_age_in_seconds = 86400
      {
        :cache_control => "max-age=#{max_age_in_seconds}",
        :acl => :public_read,
        :content_type => content_type(file),
        :content_encoding => 'gzip'
      }
    end

    def gzip path
      Tempfile.open('/tmp/gzipped_upload.') do |tempfile|
        gz = Zlib::GzipWriter.new(tempfile)
        File.open(path, 'r') { |file| gz.write(file.read) }
        gz.close
        yield tempfile.path
      end
    end

    def upload_file_to_s3 bucket, key, path, options
      puts "uploading #{path} as #{key} with options #{options}"

      uploaded_keys = [key]
      bucket.objects[key].write(Pathname.new(path), options)

      if options[:content_type].start_with?('text/html')
        extensionless_key = File.basename(key, File.extname(key))
        bucket.objects[extensionless_key].write(Pathname.new(path), options)
        uploaded_keys << extensionless_key
      end
      uploaded_keys
    end

    def upload_file bucket, key, path, options
      if options[:content_encoding] == 'gzip'
        gzip(path) { |path| upload_file_to_s3(bucket, key, path, options) }
      else
        upload_to_s3(bucket, key, path, options)
      end
    end

    def content_type file
      content_type_without_encoding =
        case  File.extname(file)
        when '.html'
          'text/html'
        when '.css'
          'text/css'
        when '.js'
          'text/javascript'
        when '.jpeg', '.jpg'
          'image/jpeg'
        when '.gif'
          'image/gif'
        else
          content_type_without_encoding = `file -b --mime-type #{file}`.chop
        end

      if content_type_without_encoding.start_with?('text/')
        # force utf8, file will always return ascii
        "#{content_type_without_encoding}; charset=utf-8"
      else
        content_type_without_encoding
      end
    end

  end
end
