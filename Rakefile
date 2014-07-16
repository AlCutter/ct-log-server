if ENV['BUNDLE_GEMFILE'].nil?
	cmd = ["bundle", "exec", $0] + ARGV
	exec *cmd
end

task :init do
	load File.expand_path("../lib/init.rb", __FILE__)
end

require 'rubygems'

task :default => :test

desc "Run a local dev server, for testing"
task :devserver => :init do
	ENV['APP_ENV'] = 'development'

	require 'rack'
	Rack::Server.start(
		:config      => 'config.ru',
		:environment => ENV['APP_ENV'],
		:server      => 'webrick',
		:Port        => 13412,
	)
end

desc "Run a local irb session for interactive play"
task :shell => :init do
	require 'irb'
	ARGV.clear
	IRB.start
end

desc "Run a local irb session in the test environment"
task :testshell => :init do
	require 'irb'

	ENV['APP_ENV'] = 'test'
	load "#{APP_ROOT}/db/schema.rb"

	ARGV.clear
	IRB.start
end

task :test => :init do
	ENV['APP_ENV'] = 'test'
end

begin
	require 'rspec/core/rake_task'

	RSpec::Core::RakeTask.new :test do |t|
		t.pattern = "spec/*_spec.rb"
	end
rescue LoadError
	$stderr.puts "RSpec not available -- no tests for you!"
end

require 'rdoc/task'
Rake::RDocTask.new do |rd|
	rd.main = "README.rdoc"
	rd.title = 'wombology API'
	rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

desc "Migrate the ENV['APP_ENV'] database to a different version (ENV['DB_VERSION'] or latest)"
task :migrate_db => :init do
	Sequel.extension :migration
	if ENV['DB_VERSION']
		puts "Migrating to schema version #{ENV['DB_VERSION']}"
		Sequel::Migrator.run(Sequel::DATABASES[0], "#{APP_ROOT}/db/migrate", :target => ENV['DB_VERSION'].to_i)
	else
		puts "Migrating to latest schema version"
		Sequel::Migrator.run(Sequel::DATABASES[0], "#{APP_ROOT}/db/migrate")
	end
end

desc "Load test fixtures into ENV['APP_ENV']'s database"
task :load_fixtures => :init do
	require 'fixture_dependencies'

	FixtureDependencies.fixture_path = "#{APP_ROOT}/spec/fixtures"
	# Load all models, because loading fixtures requires that
	Dir["#{APP_ROOT}/lib/models/*.rb"].each { |m| require m }
	fix_list = Dir["#{APP_ROOT}/spec/fixtures/*.yml"].map { |f| File.basename(f, '.yml').to_sym }
	puts "Loading all fixtures: #{fix_list.inspect}"
	FixtureDependencies.load(*fix_list)
end

desc "Run guard"
task :guard do
	ENV['APP_ENV'] = 'test'
	require 'guard'
	::Guard.start(:clear => true)
	while ::Guard.running do
		sleep 0.5
	end
end
