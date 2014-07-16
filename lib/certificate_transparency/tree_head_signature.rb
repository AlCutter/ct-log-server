# Implement the TreeHeadSignature structure as defined by RFC6962, s3.5.
#
# Instances of this class are populated by specifying either a string "blob"
# of data (which is assumed to be an existing TreeHeadSignature, and is
# parsed for values), or else passing in a hash of `:key => value` pairs
# to populate the various elements of the structure.  Any elements not
# specified will be left undefined; this may prevent the structure from
# being serialised.
#
#
# # Examples
#
# Take a binary string (which is presumed to be an encoded TreeHeadSignature)
#
#     ths = CertificateTransparency::TreeHeadSignature.new("<opaque binary string>")
#
#     puts "Version is #{ths.version}"
#     puts "Tree size is #{tbs.tree_size}"
#
module CertificateTransparency; end

class CertificateTransparency::TreeHeadSignature
	include CertificateTransparency::Helpers

	attr_reader :version, :signature_type, :timestamp, :tree_size,
	            :sha256_root_hash

	# Create a new TreeHeadSignature instance
	#
	# You can pass either an encoded TreeHeadSignature struct, as a string,
	# or else a hash of `:key => value` pairs which represent elements of
	# the structure you want to populate.
	#
	# Raises:
	#
	# * `ArgumentError` -- if `blob_or_opts` is not a String or Hash, or if
	#   the provided string cannot be decoded, or if an unknown struct
	#   element is specified in the hash.
	#
	def initialize(blob_or_opts)
		@signature_type = ::CertificateTransparency::SignatureType[:tree_hash]

		case blob_or_opts
			when String then decode_blob(blob_or_opts)
			when Hash then set_elements(blob_or_opts)
			else
				raise ArgumentError,
				      "Unknown type given to #initialize (you gave me a #{blob_or_opts.class}, but I want either a String or a Hash"
		end
	end

	# Encode the elements of this item into a binary blob.
	#
	# Returns a binary string with the encoded contents of this object, as
	# defined by RFC6962.  Will raise a `RuntimeError` if any parameters are
	# missing (haven't been defined).
	def encode
		missing = []
		[:version, :timestamp, :tree_size, :sha256_root_hash].each do |e|
			if instance_variable_get("@#{e}".to_sym).nil?
				missing << e
			end
		end

		unless missing.empty?
			raise RuntimeError,
			      "Cannot encode #{to_s}; missing element(s) #{missing.inspect}"
		end

		[@version,
		 @signature_type,
		 @timestamp,
		 htonq(@tree_size),
		 htonq(@sha256_root_hash)
		].pack("CCQQa32")
	end

	# Set the version on this TreeHeadSignature
	def version=(v)
		unless ::CertificateTransparency::Version.values.include?(v)
			raise ArgumentError,
			      "Invalid version #{v}"
		end

		@version = v
	end

	# Set the timestamp on this TreeHeadSignature
	def timestamp=(t)
		unless t.is_a? Time or t.is_a? Integer
			raise ArgumentError,
			      "Can only set timestamp to a Time or integer"
		end

		if t.is_a? Time
			t = (Time.to_f * 1000).to_i
		end

		@timestamp = t
	end

	# Set the tree size on this TreeHeadSignature
	def tree_size=(s)
		unless s.is_a? Integer
			raise ArgumentError,
			      "tree_size must be an integer"
		end

		unless s >= 0
			raise ArgumentError,
			      "tree_size cannot be negative"
		end

		@tree_size = s
	end

	# Set the sha256_root_hash on this TreeHeadSignature
	def sha256_root_hash=(h)
		unless h.is_a? String
			raise ArgumentError,
			      "sha256_root_hash must be a string"
		end

		unless h.length == 32
			raise ArgumentError,
			      "sha256_root_hash must be exactly 32 bytes long"
		end

		@sha256_root_hash = h
	end

	private
	def decode_blob(blob)
		res = blob.unpack("CCQQa32")

		self.version = res[0]
		self.signature_type = res[1]
		self.timestamp = ntohq(res[2])
		self.tree_size = ntohq(res[3])
		self.sha256_root_hash = res[4]
	end

	def set_elements(opts)
		opts = opts.dup
		[:version, :timestamp, :tree_size, :sha256_root_hash].each do |k|
			if opts.has_key?(k)
				__send__("#{k}=".to_sym, opts.delete(k))
			end
		end

		unless opts.empty?
			raise ArgumentError,
			      "Unknown struct elements passed: #{opts.keys.inspect}"
		end
	end
end
