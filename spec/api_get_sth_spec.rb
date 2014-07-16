require_relative './spec_helper'
require 'string_extension'

describe '/v1/get-sth' do
	def app
		slaveapp
	end

	let(:response) do
		get '/get-sth'
	end

	it "returns success" do
		expect(response.status).to eq(200)
	end

	it "returns JSON" do
		expect(response['Content-Type']).to eq("application/json; charset=UTF-8")
	end

	context "body" do
		let(:body) do
			JSON.parse(response.body)
		end

		%w{tree_size timestamp sha256_root_hash tree_head_signature}.each do |k|
			it "has a key '#{k}'" do
				expect(body).to have_key(k)
			end
		end

		it "has the right tree size" do
			expect(body['tree_size']).to eq(16)
		end

		it "has a timestamp" do
			expect(body['timestamp']).to be_an(Integer)
		end

		it "has the right root hash" do
			expect(body['sha256_root_hash']).to eq('+hsLiK49nc47AIdF+6ixq5wSB/aWjPRZuUEADzQIEcI=')
		end

		let(:ths) { body['tree_head_signature'].unbase64.unpack("CCna*") }

		it "has the right signature algorithm" do
			expect(ths[0]).to eq(3)
		end

		it "has the right hash algorithm" do
			expect(ths[1]).to eq(4)
		end

		it "has the right length" do
			expect(ths[2]).to eq(ths[3].length)
		end
	end
end
