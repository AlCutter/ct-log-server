# Create a new MerkleTreeLeaf structure
#
# You can create an MTL either by passing in an encoded "blob" of text to
# decode, or by passing in a TimestampedEntry object:
#
#    CertificateTransparency::MerkleTreeLeaf.new(
#      :blob => "<big blob o' stuff>"
#    )
#
# or
#
#    CertificateTransparency::MerkleTreeLeaf.new(
#      :timestamped_entry => some_object
#    )
#
class CertificateTransparency::MerkleTreeLeaf
	attr_reader :encode, :timestamped_entry, :version

	def initialize(opts)
		unless opts.is_a? Hash
			raise ArgumentError,
			      "Must pass a hash of options"
		end

		if opts.keys == [:blob]
			@encode = opts[:blob]
			_decode
		elsif opts.keys == [:timestamped_entry]
			@timestamped_entry = opts[:timestamped_entry]
			_encode
		else
			raise ArgumentError,
			      "Invalid invocation: you must pass exactly one of :blob or :timestamped_entry (You gave me #{opts.keys.inspect})"
		end

		@version = :v1
	end

	private
	def _encode
		@encode = [::CertificateTransparency::Version[:v1],
		           ::CertificateTransparency::MerkleLeafType[:timestamped_entry],
		           @timestamped_entry.encode
		          ].pack("CCa*")
	end

	def _decode
		version, leaf_type, te = @encode.unpack("CCa*")

		if version != ::CertificateTransparency::Version[:v1]
			raise ArgumentError,
			      "Unknown structure version: #{version}"
		end

		if leaf_type != ::CertificateTransparency::MerkleLeafType[:timestamped_entry]
			raise ArgumentError,
			      "Unknown MerkleLeafType: #{leaf_type}"
		end

		@timestamped_entry = ::CertificateTransparency::TimestampedEntry.new(
		                         :blob => te
		                       )
	end
end
