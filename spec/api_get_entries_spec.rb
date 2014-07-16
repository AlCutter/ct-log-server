require_relative './spec_helper'
require 'string_extension'

describe '/v1/get-entries' do
	def app
		slaveapp
	end

	let(:response) do
		get '/get-entries',
		    'start' => '3',
		    'end'   => '7'
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

		it "has an 'entries' key" do
			expect(body).to have_key('entries')
		end

		it "has a list of entries" do
			expect(body['entries']).to be_an(Array)
		end

		it "has exactly the right number of entries" do
			expect(body['entries'].length).to eq(5)
		end

		it "has leaf_input in entries" do
			expect(body['entries'][1]).to have_key('leaf_input')
		end

		it "has extra_data in entries" do
			expect(body['entries'][3]).to have_key('extra_data')
		end
	end
end
