require_relative './spec_helper'
require 'string_extension'

describe '/v1/get-entry-and-proof' do
	def app
		slaveapp
	end

	let(:response) do
		get '/get-entry-and-proof',
		    'leaf_index' => '4',
		    'tree_size'  => '16'
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

		%w{leaf_input extra_data audit_path}.each do |k|
			it "has a key '#{k}'" do
				expect(body).to have_key(k)
			end
		end

		it "has the right leaf_input" do
			expect(body['leaf_input']).
			  to eq("AAAAAAE9pe0GdAAAAAWmMIIFojCCBIqgAwIBAgISESE1Pz3s7WxTnxbUX" +
			        "mwjh7QhMA0GCSqGSIb3DQEBBQUAMFkxCzAJBgNVBAYTAkJFMRkwFwYDVQ" +
			        "QKExBHbG9iYWxTaWduIG52LXNhMS8wLQYDVQQDEyZHbG9iYWxTaWduIEV" +
			        "4dGVuZGVkIFZhbGlkYXRpb24gQ0EgLSBHMjAeFw0xMTEwMTAxNDE2Mzda" +
			        "Fw0xMzEwMTAxNDE2MzdaMIHpMR0wGwYDVQQPDBRQcml2YXRlIE9yZ2Fua" +
			        "XphdGlvbjERMA8GA1UEBRMIMDIzOTczNzMxEzARBgsrBgEEAYI3PAIBAx" +
			        "MCR0IxCzAJBgNVBAYTAkdCMRQwEgYDVQQIEwtPeGZvcmRzaGlyZTEPMA0" +
			        "GA1UEBxMGT3hmb3JkMRgwFgYDVQQJEw9CZWF1bW9udCBTdHJlZXQxCzAJ" +
			        "BgNVBAsTAklUMSMwIQYDVQQKExpUaGUgT3hmb3JkIFBsYXlob3VzZSBUc" +
			        "nVzdDEgMB4GA1UEAxMXd3d3Lm94Zm9yZHBsYXlob3VzZS5jb20wggEiMA" +
			        "0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC2VgUJx+QIlEn4vMq5Yaj" +
			        "mJEk1Lv5Kwc95oqEb2EbQMVhCJct0OA0wKJbnFGaNIo5DJHIouuz98JoH" +
			        "ixMB54EwZi5I64wvqyq1ohquTrUk4CS/4Y4odDw61dIqE2UZCxJYui9y4" +
			        "fTkptjNWmTaytw3LpGkt4Yx+AIcB+Oc7c7IPjTZEvR6L5lK9WqfZmrS/Y" +
			        "+Tgflz6W79rpgUb2CyfqLUX0Hxohw5/Zp197y4XhOwou/f+Vaju3j/Gt1" +
			        "WBAbWrKxpKAROVesfqT/H7Y/iOJ6jkPt5rqrLosStbGMpPUNNGRY0a8F1" +
			        "HBAUUzjTrRAE6CGZAPgBbcloYFc1zUsxPLcZAgMBAAGjggHRMIIBzTAOB" +
			        "gNVHQ8BAf8EBAMCBaAwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAQEwNDAyBg" +
			        "grBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3N" +
			        "pdG9yeS8wNwYDVR0RBDAwLoIXd3d3Lm94Zm9yZHBsYXlob3VzZS5jb22C" +
			        "E294Zm9yZHBsYXlob3VzZS5jb20wCQYDVR0TBAIwADAdBgNVHSUEFjAUB" +
			        "ggrBgEFBQcDAQYIKwYBBQUHAwIwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cD" +
			        "ovL2NybC5nbG9iYWxzaWduLmNvbS9ncy9nc2V4dGVuZHZhbGcyLmNybDC" +
			        "BiAYIKwYBBQUHAQEEfDB6MEEGCCsGAQUFBzAChjVodHRwOi8vc2VjdXJl" +
			        "Lmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2V4dGVuZHZhbGcyLmNydDA1B" +
			        "ggrBgEFBQcwAYYpaHR0cDovL29jc3AyLmdsb2JhbHNpZ24uY29tL2dzZX" +
			        "h0ZW5kdmFsZzIwHQYDVR0OBBYEFNp+MVYdHILBfTE6JM8O6Ul+Xwx3MB8" +
			        "GA1UdIwQYMBaAFLCwSv0cdSj4HGGqE/b6wZA9axajMA0GCSqGSIb3DQEB" +
			        "BQUAA4IBAQALHuvJlSvi3OqKwDiXBrsx0zb7DGGLAzwQCyr60iwJuc1S8" +
			        "SkWURlM0CKIq0Qupj5vYIAY2g6gDWxdf/JFMh/Rxzv90JE/xZm9YlnMh2" +
			        "Evz3glLLQ5y2x1ddc0RU9YFoeOmJcgDOROI8aQvhcn9Jdj1Yk7BkKhbQv" +
			        "/pM9ETqtSro3Xbv/qcwPTG/oRysMCrN/DUxedUr95dFjrS3zpo+6Hr7Ja" +
			        "bTcaAak40ksY+vHEQWbqm4YluJ4/c+6qfpsTTUih6//7xs92UxObeSMtW" +
			        "PaxySxedXekTPYrGt5X8XXPYoTKJnuJrxlkEBv0K7wozbn5Km2dpOqCAa" +
			        "qbf8WKa3mvAAA="
			       )
		end

		it "has the right extra_data" do
			# I'm not copy-pasting the entire extra_data
			expect(Digest::SHA256.digest(body['extra_data']).base64).
			  to eq("Uvh5JH6G1HI6R/sEYstT0fkIwqyzVauIeuVGzgF2eww=")
		end

		it "has the right audit_path" do
			expect(body['audit_path']).
			  to eq(["8pZHaCFdeQ7oqEK9w48Tvq6uNBaCuziLVYreqvqWvo8=",
			         "9mLU0Ct4gjl1/Yyxd23MTqdbvvs9eYDbWVFPFjbdBwI=",
			         "ATHnkugD7lzKf+3H2NT3JMlvFO680nDO4VsEc+FH5do=",
			         "NXH2nQ9e7q5HV46zAd7x5e4CxwPMX3lL2GmE+hte/d8="
			        ]
			       )
		end
	end
end
