module CertificateTransparency; end

module CertificateTransparency::Helpers
	def big_endian?
		@bigendian ||= [1].pack("s") == [1].pack("n")
	end

	def htonq(n)
		# This won't work on a nUxi byte-order machine, but if you have one of
		# those, I'm guessing you've got bigger problems
		big_endian? ? ([n].pack("Q").reverse.unpack("Q").first) : n
	end

	def ntohq(n)
		htonq(n)
	end
end

