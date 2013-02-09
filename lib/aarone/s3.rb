require 'aws-sdk'

module Aarone
  class S3

    def self.virginia_s3
      AWS::S3.new(:s3_endpoint => 's3.amazonaws.com')
    end

    def self.oregon_s3
      AWS::S3.new(:s3_endpoint => 's3-us-west-2.amazonaws.com')
    end

    def download_all! bucket, prefix, destination
      puts "downloading files from S3"
      bucket.objects.with_prefix(prefix).each do |object|
        puts object.key
        # if user specifies s3 path /a/b/ and saves files locally to
        # /tmp/, a file with key /a/b/c/d is saved in /tmp/c/d
        relative_filename = object.key.sub /^#{prefix}\/?/, ''
        FileUtils.mkdir_p File.dirname(File.join(destination, relative_filename))
        File.open(File.join(destination, relative_filename), 'w') do |file|
          file.write(object.read)
        end
      end
    end
  end
end
