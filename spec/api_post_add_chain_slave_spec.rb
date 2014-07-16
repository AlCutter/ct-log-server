require_relative './spec_helper'
require 'string_extension'

describe 'POST /v1/add-chain (slave)' do
	def app
		slaveapp
	end

	context "successful backend" do
		let(:response) do
			stub_request(:post, 'https://example.org/ct/v1/add-chain').
			  with(:body => {'chain' => ["base64jibberish"]}.to_json).
			  to_return(:body => '{"foo":"bar","baz":"wombat"}',
			    :headers => { 'Content-Type' => "application/json; charset=UTF-8" },
			    :status  => 200
			  )
			post '/add-chain', {'chain' => ["base64jibberish"]}.to_json
		end

		it "returns success" do
			expect(response.status).to eq(200)
		end

		it "returns JSON" do
			expect(response['Content-Type']).to eq("application/json; charset=UTF-8")
		end

		it "sends back the body we got" do
			expect(response.body).to eq('{"foo":"bar","baz":"wombat"}')
		end
	end

	context "backend request failure" do
		let(:response) do
			stub_request(:post, 'https://example.org/ct/v1/add-chain').
			  with(:body => {'chain' => ["base64jibberish"]}.to_json).
			  to_return(:body => 'lolidunno',
			    :headers => { 'Content-Type' => "text/plain; charset=UTF-8" },
			    :status  => 400
			  )
			post '/add-chain', {'chain' => ["base64jibberish"]}.to_json
		end

		it "returns Bad Request" do
			expect(response.status).to eq(400)
		end

		it "returns text" do
			expect(response['Content-Type']).to eq("text/plain; charset=UTF-8")
		end

		it "sends back the error message we got" do
			expect(response.body).to eq('lolidunno')
		end
	end

	context "backend server failure" do
		let(:response) do
			stub_request(:post, 'https://example.org/ct/v1/add-chain').
			  with(:body => {'chain' => ["base64jibberish"]}.to_json).
			  to_return(:body => 'Bad things happened',
			    :headers => { 'Content-Type' => "text/plain; charset=UTF-8" },
			    :status  => 500
			  )
			post '/add-chain', {'chain' => ["base64jibberish"]}.to_json
		end

		it "returns Server Failure" do
			expect(response.status).to eq(500)
		end

		it "returns text" do
			expect(response['Content-Type']).to eq("text/plain; charset=UTF-8")
		end

		it "sends back the error message we got" do
			expect(response.body).to eq('Bad things happened')
		end
	end
end
