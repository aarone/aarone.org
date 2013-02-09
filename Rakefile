$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), *%w[lib]))

require 'aws-sdk'
require 'aarone'
require 'fileutils'

include Aarone

def timeline_images_directory
  File.join(root, 'source/images/timeline')
end

def root
  File.dirname(__FILE__)
end

def timeline
  Timeline.new(timeline_images_directory)
end

def cloudfront_distribution_id
  Aarone::aws_config['cloudfront_distribution_id']
end

def website
  Website.new(root, website_bucket, AWS::CloudFront.new, cloudfront_distribution_id)
end

def timeline_images_bucket
  S3.oregon_s3.buckets['aarone.org.timeline']
end

def website_bucket
  S3.virginia_s3.buckets['www.aarone.org']
end

task :generate_timeline_images do
  Aarone::S3.new.download_all!(timeline_images_bucket,
                               'timeline/',
                               timeline_images_directory)
  timeline.generate_tumbnails!
end

task :generate_website do
  website.generate!
end

task :upload do
  website.upload_to_s3!
end

task :clean_images do
  timeline.clean!
end

task :clean_site do
  website.clean!
end

task :test do
  puts website.inspect
end

task :clean => [:clean_images, :clean_site]

task :default => [:generate_timeline_images, :generate_website, :upload]
