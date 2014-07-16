require 'base64'

class String
	def base64
		Base64.strict_encode64(self)
	end

	def unbase64
		Base64.decode64(self)
	end

	def enhex
		self.scan(/./m).map { |c| sprintf("%02x", c.ord) }.join
	end

	def unhex
		self.scan(/../).map { |c| c.to_i(16).chr }.join
	end
	
	def pad(len, c=" ")
		self.replace(self.to_s + c * (len-self.length))
	end
end
