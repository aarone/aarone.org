$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), *%w[lib]))

require 'aarone'
require 'fileutils'

include Aarone

def root
  File.dirname(__FILE__)
end


def bucket_name
  'www.aarone.org'
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
    FileUtils.mkdir_p timeline_images_directory
    %x[ s3cmd get -r s3://aarone.org.timeline/timeline/ #{timeline_images_directory} ]
  end

  desc 'generate timeline thumbnails (assumes originals exist)'
  # invoke as rake 'timeline:generate_thumbnails[2014]' to only
  # generate thumbnails with 2014 in the path
  task :generate_thumbnails, :filter_regex do |task,args|
    images_matching = if args.filter_regex
                        Regexp.new(args.filter_regex)
                      else
                        Regexp.new('.*')
                      end

    puts "generating with regex #{images_matching}"
    timeline.generate_tumbnails! images_matching
  end

  desc 'download timeline images from S3 and generate thumbnails'
  task :build_images => [:download_originals, :generate_thumbnails, :sanity_check]

  desc 'removes timeline images'
  task :clean do
    timeline.clean!
  end

  desc 'confirms that the timeline is in an expected state'
  task :sanity_check do
    raise "no timeline images found; run 'rake timeline:download_originals' to download and build the images" unless File.exist?(File.join(timeline_images_directory, "2007/aaron.jpg"))
  end

end

def files_with_suffix suffix
  Dir.glob(File.join(root, '_site/**/*')).
    select {|f| f.end_with?(suffix)}
end

task :copy_html_files_as_extensionless do
  files_with_suffix('.html').each do |file|
    FileUtils.cp file, file.sub(/.html$/, '')
  end
end

task :gzip_files do
  system("find _site/ -type f -exec gzip -n {} +")
  files_with_suffix('.gz').each do |file|
    FileUtils.mv file, file.sub(/.gz$/, '')
  end
end

task :jekyll_build do
  output = `jekyll build --trace 2>&1`
  raise("command failed: #{output}") unless $?.success?
end

def execute_command cmd
  puts cmd
  output = `#{cmd} 2>&1`
  raise("command failed: #{output}") unless $?.success?
end

task :build => [:clean, :jekyll_build]

desc 'uses s3cmd instead of random ruby stuff'
task :upload => [:build, :copy_html_files_as_extensionless, :gzip_files] do
  # include .html files and their extensionless variants
  html_files = Dir.glob('_site/**/*.html').
    flat_map {|f| [f, f.sub(/.html$/, '')]}.
    join(' ')

  one_minute = 60
  one_day = 60*60*24
  thirty_days = one_day * 30

  # it would be great to use sync instead of put but s3cmd will not
  # set mime types properly using sync
  execute_command "s3cmd put  --progress --acl-public   --add-header 'Content-Encoding:gzip' --add-header 'Cache-Control: max-age=#{one_minute}' -m 'text/html'  --cf-invalidate-default-index --cf-invalidate  #{html_files} s3://#{bucket_name}/"

  execute_command "s3cmd put  --progress --acl-public   --add-header 'Content-Encoding:gzip' --add-header 'Cache-Control: max-age=#{one_day}' -m 'text/plain'  --cf-invalidate-default-index --cf-invalidate _site/aaron@aarone.org.pub s3://#{bucket_name}/"

  {
    'css' => ['text/css', one_day],
    'js' => ['text/javascript', one_day],
    'gif' => ['image/gif', thirty_days],
    'jpg' => ['image/jpeg', thirty_days]
  }.each do |extension, (content_type, max_age)|
    files = Dir.glob("_site/**/*.#{extension}")
    files.each do |file|

      remote_path = file.sub(/_site\//, '')
      execute_command  "s3cmd put --progress --acl-public  --add-header 'Content-Encoding:gzip' --add-header 'Cache-Control: max-age=#{max_age}' -m '#{content_type}'  --cf-invalidate  #{file} s3://#{bucket_name}/#{remote_path}"
    end
  end
end

task :clean_site do
  %x[rm -Rf _site/*]
end

task :clean => ['timeline:clean', :clean_site]

task :default => ['timeline:sanity_check', :jekyll_build]
