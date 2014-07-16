# An implementation of the TLS 1.2 (RFC5246) "variable length" opaque type.
#
# You can create an instance of this type by passing in either content (to be
# encoded) like this:
#
#    TLS::Opaque.new(2**16-1, :value => "Hello World")
#
# or an already-encoded blob (to be decoded), like this:
#
#    TLS::Opaque.new(2**16-1, :blob => "\x00\x0BHello World")
#
# In both cases, you need to let us know how what the maximum length of the
# `value` can be, because that is what determines how many bytes the length
# field takes up at the beginning of the string.
#
# To get the encoded value out, call `#encode`:
#
#    TLS::Opaque.new(255, :value => "Hello World").encode
#    => "\x0BHello World"
#
# Or, to get the value out, call `#value`:
#
#    TLS::Opaque.new(255, :blob => "\x0BHello World").value
#    => "Hello World"
#
# Passing in a :value or :blob which is longer than the maximum length
# specified will result in `ArgumentError` being thrown.
#
class TLS::Opaque
	attr_reader :value, :encode

	def initialize(maxlen, opts)
		unless maxlen.is_a? Integer
			raise ArgumentError,
			      "maxlen must be an Integer"
		end

		@maxlen = maxlen

		if opts.keys.sort == [:blob, :value].sort
			raise ArgumentError,
			      "You cannot specify both :value and :blob"
		elsif opts.keys == [:blob]
			@blob = opts[:blob]
			_decode
		elsif opts.keys == [:value]
			@value = opts[:value]
			_encode
		else
			raise ArgumentError,
			      "You must pass #{self.class}#new exactly one of :value or :blob"
		end
	end

	private
	def _encode
		if @value.length > @maxlen
			raise ArgumentError,
					":value passed is longer than maxlen (#{@maxlen})"
		end

		len = value.length
		params = []
		lenlen.times do
			params.unshift(len % 256)
			len /= 256
		end

		params << value

		@encode = params.pack("C#{lenlen}a*")
	end

	def _decode
		if @blob.length > @maxlen + lenlen
			raise ArgumentError,
					":blob passed is too long (can be no more than #{@maxlen + lenlen})"
		end

		params = @blob.unpack("C#{lenlen}a*")
		@value = params.pop
		len = params.inject(0) { |s, c| s * 256 + c }

		if @value.length != len
			raise ArgumentError,
					":blob appears corrupt (embedded value should be #{len} bytes, but value is #{@value.length} bytes)"
		end
	end

	def lenlen
		@lenlen ||= (Math.log2(@maxlen).ceil / 8.0).ceil
	end
end
