require_relative './spec_helper'
require 'string_extension'

describe '/v1/get-roots' do
	def app
		slaveapp
	end

	let(:response) do
		get '/get-roots'
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

		it "has a 'certificates' key" do
			expect(body).to have_key('certificates')
		end

		it "has a good-looking root list" do
			expect(body['certificates']).to be_an(Array)
		end

		it "has exactly the right certs" do
			h = Digest::SHA256.hexdigest(body['certificates'].join)

			expect(h).to eq("dc8fa224afbb2b6c7494a446c257d91b61fe1985fa63d54c25bbab3d03ca1571")
		end
	end
end
