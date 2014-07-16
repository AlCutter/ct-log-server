guard 'spork', :rspec_env => { 'APP_ENV' => 'test' } do
  watch('Gemfile')             { :rspec }
  watch('Gemfile.lock')        { :rspec }
  watch('spec/spec_helper.rb') { :rspec }
end

guard 'rspec',
      :cmd            => "rspec --drb",
      :all_on_start   => true,
      :all_after_pass => true do
	watch(%r{^spec/.+_spec\.rb$})
	watch('lib/init.rb')               { :rspec }
	watch(%r{^lib/.*\.rb$})            { "spec" }
	watch('spec/spec_helper.rb')       { :rspec }
end
