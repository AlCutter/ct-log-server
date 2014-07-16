require_relative './spec_helper'
require 'string_extension'

describe '/v1/get-proof-by-hash' do
	def app
		slaveapp
	end

	let(:response) do
		get '/get-proof-by-hash',
		    'hash'      => "8pZHaCFdeQ7oqEK9w48Tvq6uNBaCuziLVYreqvqWvo8=",
		    'tree_size' => '16'
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

		%w{leaf_index audit_path}.each do |k|
			it "has a key '#{k}'" do
				expect(body).to have_key(k)
			end
		end

		it "has the right leaf_index" do
			expect(body['leaf_index']).to eq(5)
		end

		it "has the right audit_path" do
			expect(body['audit_path']).
			  to eq(["ZQTM8g4mqf80Mb7LHTEJfMWK3DlJC+ztM3WNPnYB9Yc=",
			         "9mLU0Ct4gjl1/Yyxd23MTqdbvvs9eYDbWVFPFjbdBwI=",
			         "ATHnkugD7lzKf+3H2NT3JMlvFO680nDO4VsEc+FH5do=",
			         "NXH2nQ9e7q5HV46zAd7x5e4CxwPMX3lL2GmE+hte/d8="
			        ]
			       )
		end
	end
end
