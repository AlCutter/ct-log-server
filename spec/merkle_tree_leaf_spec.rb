require_relative './spec_helper'
require_relative '../lib/certificate_transparency'

describe "MerkleTreeLeaf" do
	context "sending in a blob" do
		let(:mtl) do
			CertificateTransparency::MerkleTreeLeaf.new(
			  :blob => "\0\0\0\0\x01G(W\xEC/\0\0\0\0\fjibberjabber\0\0"
			)
		end

		it "gives us back a version" do
			expect(mtl.version).to eq(:v1)
		end

		it "has a timestamped_entry" do
			expect(mtl.timestamped_entry).to be_a(CertificateTransparency::TimestampedEntry)
		end

		context "TimestampedEntry" do
			let(:te) { mtl.timestamped_entry }

			it "has the right time" do
				expect(te.timestamp).to eq(Time.at(1405131156.527))
			end

			it "has the right entry_type" do
				expect(te.entry_type).to eq(:x509_entry)
			end

			it "has the right x509 entry data" do
				expect(te.x509_entry).to eq("jibberjabber")
			end
		end
	end

	context "creating a new MTL TE" do
		let(:te) do
			CertificateTransparency::TimestampedEntry.new(
			  :timestamp => 1405134233000,
			  :x509_entry => "ASN1 4 eva!"
			)
		end
		let(:mtl) do
			::CertificateTransparency::MerkleTreeLeaf.new(
			    :timestamped_entry => te
			  )
		end

		it "encodes the version correctly" do
			expect(mtl.encode[0]).to eq("\x00")
		end

		it "encodes the leaf_type correctly" do
			expect(mtl.encode[1]).to eq("\x00")
		end

		it "sets the ASN.1Cert length correctly" do
			expect(mtl.encode[12..14]).to eq("\0\0\x0B")
		end

		it "includes the ASN.1Cert correctly" do
			expect(mtl.encode[15..25]).to eq("ASN1 4 eva!")
		end

		it "has empty extensions" do
			expect(mtl.encode[26..27]).to eq("\0\0")
		end

		it "has nothing else at the end" do
			expect(mtl.encode.length).to eq(28)
		end
	end
end
