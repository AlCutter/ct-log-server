# Yet another structure... this time, for the CT PreCert.
#
class CertificateTransparency::PreCert
	attr_reader :issuer_key_hash, :tbs_certificate, :encode

	def initialize(opts)
		if opts.keys == [:blob]
			@encode = opts[:blob]

			@issuer_key_hash,
			  @tbs_certificate = opts[:blob].unpack("a32nCa*")

			@tbs_certificate = TLS::Opaque.new(2**24-1, :blob => @tbs_certificate).value
		elsif opts.keys.sort == [:issuer_key_hash, :tbs_certificate].sort
			unless opts[:issuer_key_hash].is_a? String
				raise ArgumentError,
				      ":issuer_key_hash must be a String"
			end

			if opts[:issuer_key_hash].length != 32
				raise ArgumentError,
				      ":issuer_key_hash must be 32 octets"
			end

			unless opts[:tbs_certificate].is_a? String
				raise ArgumentError,
				      ":tbs_certificate must be a String"
			end

			@issuer_key_hash = opts[:issuer_key_hash]
			@tbs_certificate = opts[:tbs_certificate]

			@encode = [opts[:issuer_key_hash],
			           TLS::Opaque.new(2**24-1, :value => opts[:tbs_certificate]).encode
			          ].pack("a32a*")
		else
			raise ArgumentError,
			      "Must pass either :blob or :issuer_key_hash/:tbs_certificate (you gave me #{opts.keys})"
		end
	end
end
