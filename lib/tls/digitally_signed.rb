require 'openssl'
require 'openssl_extension'

# Create a `DigitallySigned` struct, as defined by RFC5246 s4.7, and adapted
# for the CertificateTransparency system (that is, ECDSA using the NIST
# P-256 curve is the only signature algorithm supported, and SHA-256 is the
# only hash algorithm supported).
#
class TLS::DigitallySigned
	# Create a new `DigitallySigned` struct.
	#
	# Takes a number of named options:
	#
	# * `:key` -- (required) An instance of `OpenSSL::PKey::EC`.  If you pass
	#   in `:blob` as well, then this can be either a public key or a private
	#   key (because you only need a public key for validating a signature),
	#   but if you only pass in `:content`, you must provide a private key
	#   here.
	#
	#   This key *must* be generated with the NIST P-256 curve (known to
	#   OpenSSL as `prime256v1`) in order to be compliant with the CT spec.
	#   However, we can't validate that, so it's up to you to make sure you
	#   do it right.
	#
	# * `:content` -- (required) The content to sign, or verify the signature
	#   of.  This can be any string.
	#
	# * `:blob` -- An existing encoded `DigitallySigned` struct you'd like to
	#   have decoded and verified against `:content` with `:key`.
	#
	# Raises an `ArgumentError` if you try to pass in anything that doesn't
	# meet the rather stringent requirements.
	#
	def initialize(opts)
		@key = opts[:key] or raise ArgumentError, "Didn't provide :key"
		@content = opts[:content] or raise ArgumentError, "Didn't provide :content"
		@blob = opts[:blob]

		unless @key.is_a? OpenSSL::PKey::EC
			raise ArgumentError,
			      "Key must be an instance of OpenSSL::PKey::EC"
		end

		unless @blob or @key.private_key?
			raise ArgumentError,
			      "Must pass a private key to generate a signature"
		end

		if @blob
			sig_alg, hash_alg, len, @sig = @blob.unpack("CCna*")

			if sig_alg != ::TLS::SignatureAlgorithm[:ecdsa]
				raise ArgumentError,
				      "Signature specified in :blob is not ECDSA"
			end

			if hash_alg != ::TLS::HashAlgorithm[:sha256]
				raise ArgumentError,
				      "Hash algorithm specified in :blob is not SHA256"
			end

			if len != @sig.length
				raise ArgumentError,
				"Unexpected signature length " +
				  "(expected #{len}, actually got #{@sig.length}"
			end
		end
	end

	# Return a binary string which represents a `DigitallySigned` struct of
	# the content passed in.
	#
	def encode
		@blob ||= begin
			@sig = @key.sign(OpenSSL::Digest::SHA256.new, @content)

			[::TLS::SignatureAlgorithm[:ecdsa],
			 ::TLS::HashAlgorithm[:sha256],
			 @sig.length,
			 @sig
			].pack("CCna*").force_encoding("BINARY")
		end
	end

	# Verify whether or not the `signature` struct given is a valid signature
	# for the key/content/blob combination provided to the constructor.
	#
	def valid?
		unless @blob
			raise ArgumentError,
			      "Cannot validate a signature without a :blob"
		end

		@key.verify(OpenSSL::Digest::SHA256.new, @sig, @content)
	end
end
