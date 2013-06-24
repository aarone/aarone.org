$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), *%w[lib]))

require 'aws-sdk'
require 'aarone'
require 'fileutils'

include Aarone

def root
  File.dirname(__FILE__)
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

# pattern is relative to '_site/' and used in Dir.glob
# invoke from the command line like: rake upload_files['resume*']
task :upload_files, :pattern do |task, args|
  website.publish! args[:pattern]
end

namespace :timeline do

  def timeline_images_directory
    File.join(root, 'source/images/timeline')
  end

  def timeline
    Timeline.new(timeline_images_directory)
  end

  # generating timeline images requires a bunch of dependencies:
  # 1) ImageMagick
  # 2) jstalk in your path
  # 3) Acorn
  desc 'download original timeline images from S3'
  task :download_originals do
    timeline_images_bucket
    Aarone::S3.new.download_all!(timeline_images_bucket,
                                 'timeline/',
                                 timeline_images_directory)
  end

  desc 'generate timeline thumbnails (assumes originals exist)'
  task :generate_thumbnails do
    timeline.generate_tumbnails!
  end

  desc 'download timeline images from S3 and generate thumbnails'
  task :build_images => [:download_originals, :generate_thumbnails, :sanity_check]

  desc 'removes timeline images'
  task :clean do
    timeline.clean!
  end

  desc 'confirms that the timeline is in an expected state'
  task :sanity_check do
    raise "no timeline images found; run 'rake build_timeline_images' to download and build the images" unless File.exist?(File.join(timeline_images_directory, "2007/aaron.jpg"))
  end

end

desc 'generates website content'
task :generate do
  website.generate!
end

task :clean_site do
  website.clean!
end

task :clean => ['timeline:clean', :clean_site]

task :default => ['timeline:sanity_check', :generate]

desc 'publishes the website to S3'
task :publish => :default do
  website.publish!
end
