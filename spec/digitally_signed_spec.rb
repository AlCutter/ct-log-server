require_relative './spec_helper'
require 'tls/digitally_signed'

describe "DigitallySigned" do
	DS = TLS::DigitallySigned
	privkey = OpenSSL::PKey.read(File.read("#{APP_ROOT}/spec/datasets/key.pem"))
	# Yeah... so this is how you need to get *just* the public key portion of
	# an EC key out of OpenSSL::PKey::EC.  Yuck.
	pubkey  = OpenSSL::PKey::EC.new(privkey.group)
	pubkey.public_key = privkey.public_key

	context "#new" do
		it "fails without :key" do
			expect { DS.new({}) }.
			  to raise_error(ArgumentError, /:key/)
		end

		it "fails without :content" do
			expect { DS.new(:key => "x") }.
			  to raise_error(ArgumentError, /:content/)
		end

		it "barfs without :blob with a public key" do
			expect { DS.new(:key => pubkey, :content => "x") }.
			  to raise_error(ArgumentError, /private key/)
		end

		it "fails without the right type for :key" do
			expect { DS.new(:key => "x", :content => "x") }.
			  to raise_error(ArgumentError, /OpenSSL::PKey::EC/)
		end
	end

	context "#encode" do
		let(:ds) { DS.new(:key => privkey, :content => "xyzzy") }
		let(:packet) { ds.encode.unpack("CCna*") }

		it "returns a binary string" do
			expect(ds.encode.encoding.to_s).to eq("ASCII-8BIT")
		end

		it "sets the signature algorithm correctly" do
			expect(packet[0]).to eq(3)
		end

		it "sets the hash algorithm correctly" do
			expect(packet[1]).to eq(4)
		end

		it "has the correct length" do
			expect(packet[2]).to eq(packet[3].length)
		end
	end

	context "#valid?" do
		let(:sig) do
			DS.new(:key => privkey, :content => "xyzzy").encode
		end

		it "validates a correct signature" do
			ds = DS.new(:key => privkey, :content => "xyzzy", :blob => sig)
			expect(ds.valid?).to eq(true)
		end

		it "fails to validate an incorrect signature" do
			ds = DS.new(:key => privkey, :content => "some other content", :blob => sig)
			expect(ds.valid?).to eq(false)
		end
	end
end
