require 'fileutils'

def root
  File.dirname(__FILE__)
end

def bucket_name
  'www.aarone.org'
end

def aws_cli_profile
  'aarone.org'
end

namespace :timeline do

  def timeline_images_directory
    File.join(root, 'source/images/timeline')
  end

  def timeline
    Timeline.new(timeline_images_directory)
  end

  task :acorn_install_check do
    raise "Need to install Acorn to prepare images: https://flyingmeat.com/acorn/" unless File.exists? '/Applications/Acorn.app'
  end

  # generating timeline images requires Acorn
  desc 'download original timeline images from S3'
  task :download_originals do
    FileUtils.mkdir_p timeline_images_directory
    execute_command "aws --profile #{aws_cli_profile} --region us-west-2 s3 sync s3://aarone.org.timeline/timeline/ #{timeline_images_directory}"
  end

  desc 'generate timeline thumbnails (assumes originals exist)'
  # invoke as rake 'timeline:generate_thumbnails[2014]' to only
  # generate thumbnails with 2014 in the path
  task :generate_thumbnails => :acorn_install_check
  task :generate_thumbnails, :filter_substring  do |task,args|

    puts args.filter_substring
    Dir.glob(root + '/source/images/timeline/**/*')
      .select { |file|
       file.end_with?('.jpg') &&
                file.include?("-full") &&
                (args.filter_substring.nil? || file.include?(args.filter_substring)) }
      .each do |file|
      
      dimension = 350
      scaled_filename = File.join(File.dirname(file), File.basename(file).sub(/\-full/, ''))
      command = "bin/acorn-scale-to-width #{dimension} #{file} #{scaled_filename}"
      output = execute_command command
      raise "image scaling failed: #{output}" unless $?.exitstatus == 0
    end    
  end

  desc 'download timeline images from S3 and generate thumbnails'
  task :build => [:download_originals, :generate_thumbnails, :sanity_check]

  desc 'cleans up timeline images'
  task :clean do
    FileUtils.rm_rf('source/images/timeline')
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
  execute_command "jekyll build --trace"
end

def execute_command cmd
  puts cmd
  output = `#{cmd} 2>&1`
  raise("command failed: #{output}") unless $?.success?
end

task :build => [:jekyll_build]

desc 'Publish files to S3'
task :publish => [:build, :copy_html_files_as_extensionless, :gzip_files] do

  one_minute = 60
  one_day = 60 * 60 * 24
  thirty_days = one_day * 30

  html_files = Dir.glob('_site/**/*.html').
    flat_map {|f| [f, f.sub(/.html$/, '')]}.
    each do |file|

    target_path = file.sub(/^_site\//, '')
    execute_command  "aws s3 cp --region us-east-1 --profile #{aws_cli_profile} --no-guess-mime-type --acl public-read --content-encoding 'gzip' --cache-control 'max-age=#{one_day}' --content-type 'text/html' #{file} s3://#{bucket_name}/#{target_path}"
  end

  {
    'css' => ['text/css', one_day],
    'js' => ['text/javascript', one_day],
    'gif' => ['image/gif', thirty_days],
    'jpg' => ['image/jpeg', thirty_days]
  }.each do |extension, (content_type, max_age)|
    execute_command  "aws s3 sync --region us-east-1 --profile #{aws_cli_profile} --no-guess-mime-type --acl public-read --content-encoding 'gzip' --cache-control 'max-age=#{max_age}' --content-type '#{content_type}' --exclude '*' --include '*.#{extension}' _site/ s3://#{bucket_name}/"
  end

  execute_command "aws cloudfront --profile #{aws_cli_profile} create-invalidation --distribution-id E1191IBNM48QBG --paths '/*'"
end

task :clean_site do
  %x[rm -Rf _site/*]
end

task :clean => ['timeline:clean', :clean_site]

task :default => ['timeline:sanity_check', :jekyll_build]
