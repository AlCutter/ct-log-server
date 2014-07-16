require_relative './spec_helper'
require 'string_extension'

describe '/v1/get-sth-consistency' do
	def app
		slaveapp
	end

	let(:response) do
		get '/get-sth-consistency',
		    'first' => '3',
		    'second' => '11'
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

		it "has a 'consistency' key" do
			expect(body).to have_key('consistency')
		end

		it "has a good looking 'consistency' key" do
			expect(body['consistency']).to be_an(Array)
		end

		it "has the right consistency proof" do
			expect(body['consistency']).
			  to eq(["/NeD2RVJUnnzreBeKM4fCCWk+KZzG2ctHdm9LLngwJY=",
			         "h6Wo6zvO+d293qbd/5bfwMae9eh4jAZULr6i2fLAop4=",
			         "6eIbVFV8aYnfVF4/S3JN+DMPqjzBHyEMooN3rIkGbC4=",
			         "7vlLrkkM6/f4v1iHOqXktI9uey6F9n/jhm1tstpHQJc=",
			         "l4Y6ZO2QPKMETAWtAmEJBoplG+Vx/fYdIM3+27u9bs8="
			        ]
			       )
		end
	end
end
