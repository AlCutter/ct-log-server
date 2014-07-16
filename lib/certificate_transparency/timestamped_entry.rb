# Encode or parse an RFC6962 TimestampedEntry struct
#
# You can create an instance of `TimestampedEntry` in two different
# ways, corresponding to "encoding" and "decoding" a struct.
#
# To decode a binary blob into its component parts, pass in the blob, then you
# can read out the various fields:
#
#    te = CertificateTransparency::TimestampedEntry.new(:blob => "<binary>")
#    te.timestamp       # gives you back a Time object
#
#    te.entry_type      # gives you back :x509_entry or :precert_entry
#
#    te.signed_entry    # gives you back either a string
#                       # (for te.entry_type == :x509_entry)
#                       # or a CertificateTransparency::PreCert object
#                       # (for te.entry_type == :precert_entry)
#
#    te.x509_entry      # Gives back a string or nil
#
#    te.precert_entry   # Gives back a CT::PreCert or nil
#
# Conversely, you can create a struct from its parts, and then encode it:
#
#    CertificateTransparency::TimestampedEntry.new(
#      :timestamp  => <Time or BigNum>,
#      :x509_entry => <String>
#    ).encode
#
# or
#
#    CertificateTransparency::TimestampedEntry.new(
#      :timestamp     => <Time or BigNum>,
#      :precert_entry => <String>
#    ).encode
#
# Any ugliness in the arguments you pass to the constructor
# will result in a usefully descriptive `ArgumentError` being thrown.
# If the constructor passes, then you won't get any other errors
# (except generic things like `NoMethodError`)
#
class CertificateTransparency::TimestampedEntry
	attr_reader :encode, :timestamp, :entry_type, :x509_entry, :precert_entry,
	            :signed_entry

	def initialize(opts)
		if opts.keys == [:blob]
			@encode = opts[:blob]
			_decode
		elsif opts.keys.include?(:timestamp) and
		      (opts.keys.include?(:x509_entry) or
		        opts.keys.include?(:precert_entry)
		      )
			_encode(opts)
		else
			raise ArgumentError,
			      "Unknown set of options passed (must pass either :blob, or :timestamp and exactly one of :x509_entry or :precert_entry)"
		end
	end

	private
	def _decode
		ts_hi, ts_lo, entry_type, rest = @encode.unpack("NNna*")
		ts = ts_hi * 2**32 + ts_lo

		@timestamp = Time.at(ts / 1000.0)

		@entry_type = CertificateTransparency::LogEntryType.invert[entry_type]
		if @entry_type.nil?
			raise ArgumentError,
			      "Unknown LogEntryType: #{entry_type} (corrupt TimestampedEntry?)"
		end

		if @entry_type == :x509_entry
			se_len_hi, se_len_lo, rest = rest.unpack("nCa*")
			se_len = se_len_hi * 256 + se_len_lo
			@signed_entry, rest = rest.unpack("a#{se_len}a*")
		elsif @entry_type == :precert_entry
			# Holy fuck, can I have ASN1 back, please?  I can't just pass the
			# PreCert part of the blob into CT::PreCert.new, because I can't
			# parse the PreCert part out of the blob without digging *into* the
			# PreCert part, because the only information on how long TBSCertificate
			# is is contained *IN THE PRECERT!*
			#
			# I'm surprised there aren't a lot more bugs in TLS
			# implementations, if this is how they lay out their data
			# structures.
			ikh, tbsc_len_hi, tbsc_len_lo, rest = rest.unpack("a32nCa*")
			tbsc_len = tbsc_len_hi * 256 + tbsc_len_lo
			tbsc, rest = rest.unpack("a#{tbsc_len}a*")
			@signed_entry = ::CertificateTransparency::PreCert.new(
			                    :issuer_key_hash => ikh,
			                    :tbs_certificate => tbsc
			                  )
		end

		case @entry_type
			when :x509_entry    then @x509_entry    = @signed_entry
			when :precert_entry then @precert_entry = @signed_entry
			else
		end

		ext_len, ext = rest.unpack("na*")
		if ext_len.nil?
			raise ArgumentError,
			      ":blob corrupted (ended before ext_len was found)"
		elsif ext_len != 0
			raise ArgumentError,
			      "I don't know how to deal with CtExtensions!"
		end
	end

	def _encode(opts)
		signed_entry, entry_type = if opts.keys.include?(:x509_entry)
			[TLS::Opaque.new(2**24-1, :value => opts[:x509_entry]).encode, ::CertificateTransparency::LogEntryType[:x509_entry]]
		elsif opts.keys.include?(:precert_entry)
			[opts[:precert_entry].encode, ::CertificateTransparency::LogEntryType[:precert_entry]]
		else
			raise ArgumentError,
			      "CAN'T HAPPEN: Unknown signed_entry type (report a bug, plz)"
		end

		ts = opts[:timestamp].is_a?(Time) ? (opts[:timestamp].to_f*1000).to_i : opts[:timestamp]
		ts_hi = ts / 2**32
		ts_lo = ts % 2**32
		@encode = [ts_hi, ts_lo, entry_type, signed_entry, 0].pack("NNna*n")
	end
end
