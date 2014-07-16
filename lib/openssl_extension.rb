require 'openssl'

unless OpenSSL::PKey::EC.instance_methods.include?(:private?)
	OpenSSL::PKey::EC.class_eval("alias_method :private?, :private_key?")
end
