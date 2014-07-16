require 'spork'

Spork.prefork do
	load File.expand_path('../../lib/init.rb', __FILE__)

	require 'bundler'
	Bundler.setup(:default, :test)
	require 'rspec/core'

	require 'rack/test'
	require 'rspec/mocks'
	require 'webmock/rspec'

	require 'pry'
#	require 'plymouth'
	require 'rspec-context-let'

	module AppHelper
		def slaveapp
			Rack::Builder.new do
				run CertificateTransparency::API::V1.new(
				      :dai        => ::CertificateTransparency::DAI.new(
				                         "#{APP_ROOT}/spec/datasets/certs.gdb",
				                         nil
				                     ),
				      :master_url => "https://example.org",
				      :logger     => Logger.new("/dev/null")
				    )
			end
		end

		def masterapp
			Rack::Builder.new do
				run CertificateTransparency::API::V1.new(
				      :dai              => ::CertificateTransparency::DAI.new(
				                               "#{APP_ROOT}/spec/datasets/certs.gdb",
				                               nil
				                           ),
						:private_key_file => "#{APP_ROOT}/spec/datasets/key.pem",
				      :queue_dir        => "#{APP_ROOT}/spec/datasets/queue",
				      :logger           => Logger.new("/dev/null")
					 )
			end
		end
	end

	RSpec.configure do |config|
		config.fail_fast = true
#		config.full_backtrace = true
		config.treat_symbols_as_metadata_keys_with_true_values = true

		config.expect_with :rspec do |c|
			c.syntax = :expect
		end

		config.include AppHelper
		config.include Rack::Test::Methods
	end
end

Spork.each_run do
	require 'certificate_transparency/api/v1'
end
