#!/usr/bin/env ruby

require 'aws-sdk'
require 'stringio'
require 'tempfile'
require 'time'
require 'uri'
require 'yaml'
require 'zlib'

S3_CONFIG_PATH = File.expand_path('~/.s3.yml')
update_distribution = true

config = YAML.load_file(S3_CONFIG_PATH)

def config_usage
  puts <<-USAGE
#{$0} requires a file in #{S3_CONFIG_PATH} with the following config:

s3_id: <your aws access key>
s3_secret: <your aws secret key>
s3_bucket: <a bucket name>
cloudfront_distribution_id: <distribution id>
USAGE
  exit(1)
end

def usage
  puts "#{$0} <src-dir>"
end

def gzip path
  Tempfile.open("/tmp/gzipped_upload") do |tempfile|
    gz = Zlib::GzipWriter.new(tempfile)
    File.open(path, 'r') { |file| gz.write(file.read) }
    gz.close
    yield tempfile.path
  end
end

def upload_to_s3 bucket, key, path, options
  puts "uploading #{path} as #{key} with options #{options}"

  bucket.objects[key].write(Pathname.new(path), options)

  if options[:content_type].start_with?('text/html')
    bucket.objects[File.basename(key, File.extname(key))].write(Pathname.new(path), options)
  end
end

def upload_file bucket, key, path, options
  if options[:content_encoding] == 'gzip'
    gzip(path) { |path| upload_to_s3(bucket, key, path, options) }
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

def upload_options file
  {
    # cache for a day
    :cache_control => 'max-age=86400',
    :acl => :public_read,
    :content_type => content_type(file),
    :content_encoding => 'gzip'
  }
end

def upload(source, bucket)
  source += "/" unless source.end_with?("/")
  bucket.objects.each &:delete

  keys = []
  Dir.glob(source + '**/*').each do |file|
    key = file[source.length..-1]
    path = File.expand_path(file)
    next if File.directory?(path)

    keys << key
    upload_file(bucket, key, path, upload_options(path))
  end
  keys
end

(config_usage and exit(1)) unless
  ['s3_id', 's3_secret', 's3_bucket', 'cloudfront_distribution_id'].all? do |config_symbol|
  config.has_key?(config_symbol)
end

source_dir = if ARGV[0] && File.exists?(File.expand_path(ARGV[0]))
               ARGV[0]
             else
               usage
               exit(1)
             end

AWS.config(:access_key_id => config['s3_id'],
           :secret_access_key => config['s3_secret'])

s3 = AWS::S3.new
cloudfront = AWS::CloudFront.new

keys = upload(source_dir, s3.buckets[config['s3_bucket']])

if update_distribution
  puts "updating cloudfront distribution '#{config['cloudfront_distribution_id']}'; for paths: #{keys.inspect}"
  cloudfront.client.create_invalidation(:distribution_id => config['cloudfront_distribution_id'],
                                        :invalidation_batch => {
                                          :paths => {
                                            :quantity => keys.length,
                                            :items => keys.collect{|key| URI.encode('/' + key)}
                                          },
                                          :caller_reference => Time.now.utc.iso8601
                                        }
                                        )
end
