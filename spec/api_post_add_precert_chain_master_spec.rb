require_relative './spec_helper'
require 'string_extension'

describe 'POST /v1/add-pre-chain' do
	def app
		masterapp
	end

	let(:privkey) { OpenSSL::PKey.read(File.read("#{APP_ROOT}/spec/datasets/key.pem")) }

	# Yeah... so this is how you need to get *just* the public key portion of
	# an EC key out of OpenSSL::PKey::EC.  Yuck.
	let(:pubkey) do
		pubkey = OpenSSL::PKey::EC.new(privkey.group)
		pubkey.public_key = privkey.public_key
		pubkey
	end

	let(:cert) do
		"MIIC+TCCAeGgAwIBAgIRAN3D3JqjoESPk7KeLNH6gLwwDQYJKoZIhvcNAQELBQAw" +
		"IDEeMBwGA1UEAwwVRHVtbXkgSW50ZXJtZWRpYXRlIENBMCAXDTE0MDcwNjAzMDQ0" +
		"OFoYDzIxMTQwNzE3MDMwNDQ4WjAqMSgwJgYDVQQDDB9Qb2lzb25lZCBFbmQgRW50" +
		"aXR5IENlcnRpZmljYXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA" +
		"57z1hzLLct4gx7ZNZXu3O7p8IFr+Uxt3YygdIMxTp1mO2ZRPJcXfTQKl1hkvmJNy" +
		"TtPBnonlXHHjjB0wuqf/VnN+mHIk4WhUORn7ifaCq+q9Gr4UN+vcnjE5V5gDmTXp" +
		"rtldZ2gZeWeNowExc3m9RgaA0by0s7ikQTjRX5LF6jkldbKdsjVRZVRsioW4+NQH" +
		"TFLGtVgEkGRVvTGyePlKikwoWhPMjl4h8NrK8O+7DAxZkXr0MV6nae5Ham7e87jH" +
		"RjJ3isp/a6ul6XVizzwCtgK+r47bwpCS//ESCVv7ak7vykS/ObrQsqqg8qYiFT3i" +
		"MYL3B7TT/wgPlXerLWDcBwIDAQABoyIwIDALBgNVHQ8EBAMCAQYwEQYKKwYBBAHW" +
		"cQIEAwEB/wQAMA0GCSqGSIb3DQEBCwUAA4IBAQAKnjQpSa6K82WKhBtu2RUt+JyZ" +
		"NS3/eK/L26N+JrIjLuNpunqk/+Vwr2ztRYUiEfzWhyLhZnCaEDmIbl0pJTDUe+oT" +
		"0Me2JA0eBr44YYc9op980ySEzsru1ZEk4Vt8p3EBElhuqCDT5bnHMW/oBiyHhBt9" +
		"qzt5hcrGE2pjfdABceVVCUQNwaFwtw5gWIy3r0bsZDolziKfuMyk/z/9rO5o+mu8" +
		"TjcTy9EDE+73WRa2AxFZjh3u22Zd+/1eJm/TO79Z9Qk+3euZsxVn2UFkLJJ0PC+Y" +
		"O9iOGhPFV1hXDPE8QD/PMFV9vpALcPECKUVLy0qxlDNo+6xIz0ln9CX1vYJJ"
	end

	let(:inter) do
		"MIIC5DCCAcygAwIBAgIQQHqXhrFCRtmS7Gw6kSjCzDANBgkqhkiG9w0BAQsFADAY" +
		"MRYwFAYDVQQDDA1EdW1teSBSb290IENBMCAXDTE0MDcwNjAzMDQ0OFoYDzIxMTQw" +
		"NzE3MDMwNDQ4WjAgMR4wHAYDVQQDDBVEdW1teSBJbnRlcm1lZGlhdGUgQ0EwggEi" +
		"MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCjXS2NSM5LgUoul4iwBMOCy0pA" +
		"9OxBMwp50wmOML2wb3uH87JHyT+NkaGryyyl9svYdQMV7XRHjwLXC3WOiIB2GhqH" +
		"7+UPbClbWjtFqXbkcjDxfQ3K8VxARtowbUsKIb7Lx3s0jkiT/HocixvwIrunq1aJ" +
		"yE8/3md5X+5W6oOBxkBEAvuq1Lvuitc0bl5a5em+mKE63JTyE1lew5O3uIPG5Wh/" +
		"zB4n4bjOliMI1Ku3HcCVlKe09qrzXxHh80ZO0q+6FNgeiAiCJVl7++Rq/1wVGLpx" +
		"EZzJkMdEWbx3axga3aDOCXjzBwZX8ka7NamGyaOW5M/pxo6rxqH2WYQ7DUhlAgMB" +
		"AAGjIDAeMAsGA1UdDwQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEB" +
		"CwUAA4IBAQBIC2PKbUaH8xJZPGPA1HpuDZQBpbrHL5kdtQoHw9AS8QiaS8Heq2w0" +
		"Lyn0Z4hhqUJkn4VsOP9T1as58DN1m6O978LVlpaaZeXeuSxeeculyZovrzaLVNzo" +
		"aoRCGazeS/5mTT/nRvGI1U6LQiApOJuMmw1Lj15A8o+6SletbCd3hVLVpyasIXSh" +
		"Z0RFR5nVy1ZYDvA+yMPdYCDPSCO4ApYdh1y86hRiPPGk+p8HFZBK8ILNBy0PCRDk" +
		"7djIKF7pODVD9gCHJUlbA43/pt+9fiSPcCA+3/mgb64J49EF1Uxp1Nn3S8JtL6aT" +
		"+GRnXEL/CSAQ+2TaHB5QjoTZu5V9cKQe"
	end

	after(:each) do
		Dir["#{APP_ROOT}/spec/datasets/queue/*.json"].each { |f| File.unlink(f) }
	end

	context "poisoned cert chained to a trusted root" do
		let!(:response) do
			post '/add-pre-chain', {'chain' => [cert, inter]}.to_json
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

			%w{sct_version id extensions signature}.each do |k|
				it "has a key '#{k}'" do
					expect(body).to have_key(k)
				end
			end

			it "has the right sct_version" do
				expect(body['sct_version']).to eq(0)
			end

			it "has the right ID" do
				expect(body['id']).
				  to eq("Iobsqh02nkRoDGukQg1H0H1p6BL7vb5i1Yw6M4zKBqo=")
			end

			it "has a vaguely appropriate timestamp" do
				expect(body['timestamp'] / 1000).
				  to be_within(2).of(Time.now.to_i)
			end

			it "has a valid signature" do
				sig = body['signature'].unbase64[4..-1]  # Skip the DigitallySigned gibberish
				tbs = OpenSSL::ASN1.decode(cert.unbase64).value[0].to_der
				issuer_key = OpenSSL::X509::Certificate.new(inter.unbase64).public_key.to_der
				ikh = Digest::SHA256.digest(issuer_key)
				precert = [ikh, tbs.length, tbs].pack("a*na*")
				ct = [0,0,                       # sct_version, signature_type
				      body['timestamp']/2**32,   # timestamp_hi
				      body['timestamp']%2**32,   # timestamp_lo
				      1,                         # entry_type
				      precert.length/256,        # precert_entry_len_hi
				      precert.length%256,        # precert_entry_len_lo
				      precert,                   # cert
				      0                          # extensions length
				     ].pack("CCNNnnCa*n")

				v = pubkey.verify(OpenSSL::Digest::SHA256.new, sig, ct)
				expect(v).to be(true)
			end
		end

		context "queue" do
			let(:qents) do
				Dir["#{APP_ROOT}/spec/datasets/queue/*.json"].map do |f|
					JSON.parse(File.read(f))
				end
			end
			
			it "only has one entry" do
				expect(qents.length).to eq(1)
			end
			
			it "puts the same SCT in the queue as we sent back" do
				response

				expect(qents[0]['sct']).to eq(response.body)
			end

			it "has vaguely correct-looking leaf_input data" do
				expect(qents[0]['leaf_input']).to match(%r{^[A-Za-z+/=]+})
			end

			it "has the right chain" do
				expect(qents[0]['chain']).
				  to eq(["3NGuqEULnuSBpWOPYfvn0Ufzo/fsplGMrZmyW480oxI=",
				         "+NjzNHvI6diT5gF66jxKxPklpMEQFT9h93hlToajcno="
				        ]
				       )
			end
		end
	end
end
