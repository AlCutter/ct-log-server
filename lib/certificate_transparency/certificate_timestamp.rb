require 'tls'

# Implement the CertificateTimestamp structure as defined by RFC6962, s3.2.
#
# Instances of this class are populated by specifying the set of variables
# that are required to assemble the struct that is digitally signed to
# generate the SignedCertificateTimestamp.  All of these values are passed
# into the constructor as a hash.
#
# The keys to use are:
#
# * `:timestamp` -- either a Time object or an integer timestamp value.
#
# * `:x509_entry` / `:precert_entry` -- Exactly one of these must be provided;
#   it is the raw certificate that we're all interested in.
#
class CertificateTransparency::CertificateTimestamp
	attr_reader :encode

	def initialize(opts)
		unless opts.is_a? Hash
			raise ArgumentError,
			      "opts must be a hash"
		end
		if opts.keys.sort == [:timestamp, :x509_entry].sort
			@entry_type = ::CertificateTransparency::LogEntryType[:x509_entry]
			@signed_entry = opts[:x509_entry]
		elsif opts.keys.sort == [:timestamp, :precert_entry].sort
			@entry_type = ::CertificateTransparency::LogEntryType[:precert_entry]
			@signed_entry = opts[:precert_entry]
		else
			raise ArgumentError,
			      "Invalid set of keys"
		end

		ts = opts[:timestamp]
		@timestamp = ts.is_a?(Time) ? (ts.to_f*1000).to_i : ts

		@encode = [::CertificateTransparency::Version[:v1],
		           ::CertificateTransparency::SignatureType[:certificate_timestamp],
		           @timestamp / 2**32,
		           @timestamp % 2**32,
		           @entry_type,
		           TLS::Opaque.new(2**24, :value => @signed_entry).encode,
		           TLS::Opaque.new(2**16, :value => "").encode   # CtExtensions, guaranteed to be empty
		          ].pack("CCNNna*a*")
	end
end
