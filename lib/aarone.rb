require 'aarone/timeline'
require 'aws'

module Aarone
  S3_CONFIG_PATH = File.expand_path('~/.s3.yml')

  def self.aws_config
    @config ||= YAML.load_file(S3_CONFIG_PATH)

    raise "missing 's3_id' or 's3_secret' key in #{S3_CONFIG_PATH}" unless @config['s3_id'] && @config['s3_secret']

    @config
  end

  AWS.config(:access_key_id => aws_config['s3_id'],
             :secret_access_key => aws_config['s3_secret'])

end
