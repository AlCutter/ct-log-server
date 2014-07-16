def parse_extra_data(s)
	chain = []

	# These strings start off with the length of the whole string... pointless
	len_hi, len_lo, rest = s.unpack("nCa*")
	len = len_hi*256+len_lo

	if len != rest.length
		raise RuntimeError, "Corrupt string passed (data is #{rest.length}, but header says it should be #{len})"
	end

	s = rest
	until s == ""
		len_hi, len_lo, rest = s.unpack("nCa*")
		len = len_hi*256+len_lo
		der, s = rest.unpack("a#{len}a*")
		chain << OpenSSL::X509::Certificate.new(der)
	end

	chain
end
