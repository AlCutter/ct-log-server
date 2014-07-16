require_relative './spec_helper'
require 'string_extension'

describe 'POST /v1/add-chain' do
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
		"MIIC3TCCAcWgAwIBAgIRAK2dVKm2KkVRtq/a/egFImAwDQYJKoZIhvcNAQELBQAw" +
		"IDEeMBwGA1UEAwwVRHVtbXkgSW50ZXJtZWRpYXRlIENBMCAXDTE0MDcwNjAzMTAw" +
		"M1oYDzIxMTQwNzE3MDMxMDAzWjAhMR8wHQYDVQQDDBZFbmQgRW50aXR5IENlcnRp" +
		"ZmljYXRlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvvz87TGqV3RS" +
		"BzPZnIAD+aeaROekPE1mOm9kWeh3ZaLNpS+Omd0Fgn2Sy05h95C74aW8l85Zh6K2" +
		"VHuYNFsStOmy8oKHQrXahcCcetar50LFGaYdwp47B0mNvpxXhd7pOD+VvnsCd7sM" +
		"fkj5G5Musx8nirhUQw6GinQV4J1UIOuwzTJDm8X0oNuxjYF0euELu1LM++RiUSVI" +
		"rIsKQqb0hQ+rL0P7a138XAtnifqIldfrPLY9WyO+UBgKvHLxaZeAAPLmXlNg/NWf" +
		"0za9103M2f5mv1GbX03/gt0aHaBo+YxOn+8QIPEaSlZaoHgd1oC/y4wNG+aYrfeT" +
		"7kunavSZ8wIDAQABow8wDTALBgNVHQ8EBAMCAQYwDQYJKoZIhvcNAQELBQADggEB" +
		"AAt0c9stksA5DU9SZY0YbW5CqWb4oGfFh+y8MxKRcxedhD7lzB/Yu3gCVhDBKAuk" +
		"UL9TEKVzNwZhNjhq/crV+ciy1jM5S3SV1s6n/R/iVqpU+GcxTEViTgU3EYWuRzEA" +
		"NQ2goLyya/lSl4N/vcbpgjzzn16ary5RJVh5/n1N6pzKBtXO0GYtUYk6H1aT0Xlz" +
		"rj0BZlPbv4qidOqA9g3cO7WJDefxFg24nmQeu5gKeyGD+PCG7BsnBqSr4JWTPs/v" +
		"RXfyfVTpUKUV37kWYXtW/ElET/Z9hwImNLjnHh0uiQzKIqvp9B0WtExkEr/WNJY1" +
		"rjMv2ANXt+FF8x2OuTfdRuU="
	end

	let(:inter) do
		"MIIC5TCCAc2gAwIBAgIRAL1Hin0daEjpqw/fp2RSWfcwDQYJKoZIhvcNAQELBQAw" +
		"GDEWMBQGA1UEAwwNRHVtbXkgUm9vdCBDQTAgFw0xNDA3MDYwMzEwMDNaGA8yMTE0" +
		"MDcxNzAzMTAwM1owIDEeMBwGA1UEAwwVRHVtbXkgSW50ZXJtZWRpYXRlIENBMIIB" +
		"IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy4E1+elmKappz8L4bj8H6tNf" +
		"ANgBY2srUY8e6JlY95qG2TW8DE4i7aGQ0qDVPjW9FgZS3RAaxAEC0HJOmDCLjof3" +
		"Q8w2ZX/Vezkr6uvMEsHkQVLd9VPGYElNV0+TcKDKgTk8qmhHSn7ZtU2Aw7oJUMNm" +
		"vsdYQwAubigEx1rNPNj+aWupRR3OswUo+/Zkwf+sv+BOklIpskUGbD7r6OiKvPDs" +
		"urRN4O6RntMpy7R2fUVcbj+YBZUWCetsyNXSFPRVXKUmuJ8gLyD+Xq4SReTiBLNV" +
		"c82CZGysDt+Yfke9PtaKljLWW03144dygtGmFvOng7TBIlBBOthIV+otz71t0QID" +
		"AQABoyAwHjALBgNVHQ8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0B" +
		"AQsFAAOCAQEAKm2DjrCVDq50qdjbB90UOzmuSSFTo2WguIWz11U1gwnqip1jCkx4" +
		"12FB4d+wk2mwpQs+cY1F9oMx6pLvKmUt6TmSVBDVsyIIHF7kqG6dmfivckw454/z" +
		"i1SxKHh+pHDHUF/5ghUNY514pdSFVB/QvU7BZtsOW3kjcs5iyyZij+vzODL2oSWC" +
		"dpg0aUTqFsMbxvThk0d1jq3pIVTzsf1fGtz0fEtJwUrLUfloY99Pnme7y5ZZGBei" +
		"mCGvHsX8FMFFVYTJpbsiRVOIWDC1RQvZtUwBj7tPvi5uTlFTOpikyZ80hSGVfGaI" +
		"b4uYm3hOwUiSkvL8kZTt0lFwMbstnh9Dzg=="
	end

	let(:geotrust_inter) do
		"MIIEATCCAumgAwIBAgIDAjpcMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNVBAYTAlVT" +
		"MRYwFAYDVQQKEw1HZW9UcnVzdCBJbmMuMRswGQYDVQQDExJHZW9UcnVzdCBHbG9i" +
		"YWwgQ0EwHhcNMTEwNDExMjIzMTEwWhcNMjEwNDA4MjIzMTEwWjBoMQswCQYDVQQG" +
		"EwJVUzEXMBUGA1UEChMOVm9sdXNpb24sIEluYy4xHTAbBgNVBAsTFERvbWFpbiBW" +
		"YWxpZGF0ZWQgU1NMMSEwHwYDVQQDExhWb2x1c2lvbiwgSW5jLiBEViBTU0wgQ0Ew" +
		"ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCKT+2rliplzVjrVqTijHOS" +
		"vHPliSA3hVYbdWY2AqTJPAwMTg2jFQnCSnlgxr+/owXDjWN99M79JdieWULgKkA+" +
		"E9Q2JOIuqZzvEFCUwfGV02SX7lq/AkM5E/Ifzss09FZmJvXGVHaNCaa86LeidhyG" +
		"A1u5Lz9w7pZYqVwSusJN+kilwnxgrSAvqvm+yLNKpef43IAS5foqwV/cNHBSVvIv" +
		"KZx1gN0tet7wlwos+5nr4SOeZUbDbyeyose2LCF/dDyJhrvixYIL8NbHOLur3Yb2" +
		"pAhStLUjshv9pslg9Olr22PoFS737TSQK0ztChcmhS/KR7lMLXXOIfzq1H/qVWXp" +
		"AgMBAAGjgdkwgdYwHwYDVR0jBBgwFoAUwHqYaI2J+6sFZAwRfap9ZbjKzE4wHQYD" +
		"VR0OBBYEFMfl1IdwhbgV7+fBL1Cfl9sjYX4LMBIGA1UdEwEB/wQIMAYBAf8CAQAw" +
		"DgYDVR0PAQH/BAQDAgEGMDoGA1UdHwQzMDEwL6AtoCuGKWh0dHA6Ly9jcmwuZ2Vv" +
		"dHJ1c3QuY29tL2NybHMvZ3RnbG9iYWwuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggr" +
		"BgEFBQcwAYYYaHR0cDovL29jc3AuZ2VvdHJ1c3QuY29tMA0GCSqGSIb3DQEBBQUA" +
		"A4IBAQBwcs009ff5iepNys32JRvY1xPirIQoT7x4TNrsrHmtkGzqbBk6Yix+OJLk" +
		"7hTTKyRNYXNPKEShTFluHJwjvZE+scR56omgm6+d7QrUw+hiwcTXrd7kQFqG/Pfr" +
		"s9zJu3v9IyltTtFXKL5B4Y/4Dagh64bxMhYcegpbAaRU6ZHfIKCADaeMUvL/xX5D" +
		"ii0iWO5MFGhbMWrfdmM/oagwBKkPCfWgM2dAo5weTtsWGtZz8/HnAzQRpAzZHgVq" +
		"CJscdtxGaQVPkrctHvI0kaeTQm1rnZsvNsmfxh69YI3I9CvN+sh9/IE+QMsL3aCn" +
		"JwBsyFcVgDQxqiysiX63EOFhHQtt"
	end

	let(:entry8) do
		"MIIFgDCCBGigAwIBAgICchgwDQYJKoZIhvcNAQEFBQAwaDELMAkGA1UEBhMCVVMxFzAVB" +
		"gNVBAoTDlZvbHVzaW9uLCBJbmMuMR0wGwYDVQQLExREb21haW4gVmFsaWRhdGVkIFNTTD" +
		"EhMB8GA1UEAxMYVm9sdXNpb24sIEluYy4gRFYgU1NMIENBMB4XDTEzMDEwNTE4MDUxNVo" +
		"XDTE0MDMwOTE4MDYzOFowgaAxKTAnBgNVBAUTIGs5YW1YeFQwTmFRc2xocUZ6UU93d1Bq" +
		"dWRwY2F1aE5GMRMwEQYDVQQLEwpHVDU3MDM1MzM5MRUwEwYDVQQLEwxWb2x1c2lvbiBTU" +
		"0wxITAfBgNVBAsTGERvbWFpbiBDb250cm9sIFZhbGlkYXRlZDEkMCIGA1UEAxMbd3d3Lm" +
		"FydHdhcmVob3VzZWNlbnRyYWwuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgK" +
		"CAQEA6BMv56whiP2up+T1nsrnk+v2R7tgujSJQf6iQPS1NZHqkW3K8D1dsfRMqeFNPCeZ" +
		"pRaQMvXcpwsmdUGb0rgqXPq622MPkZ1X3Nyi5PtMaveZ5rtaOygKaH9sUNLU5tp1rcGxd" +
		"0d20Rtt4p1/xT8h37nhjqNoN2Fl9zfLss65PbhukjCXMDbX4kMViv4GYgygo4BiXJ2Cy2" +
		"lyO/OQFMg4lfmRdRUT9j/rzCudcqxSNu+fYNwWgEnKe3OUAdx2j3iu5f9HD5gR4E7iyFW" +
		"UnQPC3fKu/ZmxyE65VNO0heJ5iPmL97F29bkNyZxACVHGBli79pf2RgRVBG+xUs/8SR5L" +
		"SQIDAQABo4IB+TCCAfUwHwYDVR0jBBgwFoAUx+XUh3CFuBXv58EvUJ+X2yNhfgswgZQGC" +
		"CsGAQUFBwEBBIGHMIGEMDoGCCsGAQUFBzABhi5odHRwOi8vdm9sdXNpb24tb2NzcC5kaW" +
		"dpdGFsY2VydHZhbGlkYXRpb24uY29tMEYGCCsGAQUFBzAChjpodHRwOi8vdm9sdXNpb24" +
		"tYWlhLmRpZ2l0YWxjZXJ0dmFsaWRhdGlvbi5jb20vdm9sdXNpb24uY3J0MA4GA1UdDwEB" +
		"/wQEAwIFoDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwPwYDVR0RBDgwNoIbd" +
		"3d3LmFydHdhcmVob3VzZWNlbnRyYWwuY29tghdhcnR3YXJlaG91c2VjZW50cmFsLmNvbT" +
		"BQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vdm9sdXNpb24tY3JsLmRpZ2l0YWxjZXJ0dmF" +
		"saWRhdGlvbi5jb20vY3Jscy92b2x1c2lvbi5jcmwwDAYDVR0TAQH/BAIwADAdBgNVHQ4E" +
		"FgQUaso0JhGbDgROGRRDy+DoT3OcgSEwTAYDVR0gBEUwQzBBBgpghkgBhvhFAQc2MDMwM" +
		"QYIKwYBBQUHAgEWJWh0dHA6Ly93d3cuZ2VvdHJ1c3QuY29tL3Jlc291cmNlcy9jcHMwDQ" +
		"YJKoZIhvcNAQEFBQADggEBADIPBJubYSfBZfF0jwz1wsWasV4c/7Cu/up6RYiG9DtQje7" +
		"LOAW5bF3eKvv8RxBxVeDkOE2yQuIXKliCfddTJFzcPMfnn+/PvfiNChHJtGcWexwqTQNT" +
		"2EjdgIQ4el2ptNyIqriOA2dpS6k0gEXirp/ED1udYvVZ+g6U48ZR7wr6ej2Ko9TSds/8N" +
		"42JXEfuFQDRSteqTFX2IVcKRKxGVotNuy5mohT94RIQfwleW8A/uiuxAfsqUidV3/1YzW" +
		"WJ7Nu8xpW4emrdj5phP+/ydj1dZUrHLU6SULekh+KQgrxDzPKyttiDblnm7zy+U67pJwX" +
		"2tXBHxCF0vZTrOLY9QOU="
	end

	let(:untrusted_chain) do
		[
			"MIIC8zCCAdugAwIBAgIRAIEy1yykTEtYqfk9ZT9QOugwDQYJKoZIhvcNAQELBQAw" +
			"KDEmMCQGA1UEAwwdVW50cnVzdHdvcnRoeSBJbnRlcm1lZGlhdGUgQ0EwIBcNMTQw" +
			"NzA0MDgyNzUyWhgPMjExNDA3MTUwODI3NTJaMC8xLTArBgNVBAMMJFVudHJ1c3R3" +
			"b3J0aHkgRW5kIEVudGl0eSBDZXJ0aWZpY2F0ZTCCASIwDQYJKoZIhvcNAQEBBQAD" +
			"ggEPADCCAQoCggEBAMJV57N7hWh4Y06tUuiqBrrSclvMYubT0DPQZV9S+Pv1WPxN" +
			"eLJgqbI1KT1Az66FWewRZlQS9pdTUBWxNiXpwxp3T7eappRrIFu1HBPz2EqJHUEn" +
			"CA7u470oDbNyN6pDhaHC7dYxfrQDvfLW4hrUoyO5sYqyk2UbVjscIQG3ryh+BYeq" +
			"4Wm7nbFPZlaKSRIAWpZBJUXq4BdzmaT9dRskVLFrJxbv5N11+JPWb9foSfqYV/QJ" +
			"74U8foxHLBX3UAbrvfKO4hgnCe+yTBphShK5wDXp5SjoKj1jZzY74mmx2XDWjpBQ" +
			"B2J98OPS7m7NXwmwlP2IBrU+ulWcTQDbUbYgm8sCAwEAAaMPMA0wCwYDVR0PBAQD" +
			"AgEGMA0GCSqGSIb3DQEBCwUAA4IBAQB+PMIsrufNZETnUEkAbhqMizzFRk6qdZlF" +
			"tjPiJwTCb73Fakx1I2Du61MavQ1mnjdoeWjx1e9tiLggGvdXiShVGeBHLqg5dQln" +
			"NBnDD9rJ0Zk9nn4rLX1IY2IJCrgJNW+mOCyDeN+vk7VjRfQz7pUW0V75AdrDbGtH" +
			"uDPYBpMbGXVCti1u3zbg1QYQpuz5Rr3WyqdsfaIajAy7lkkz+vcHJv5fXM9sVNdy" +
			"4s/8EcK8apiZvjlwjo93C9rQxBBin4Yb33B4CNVzW8rWyJyzNFn088Re6hOB1gXs" +
			"txi71C2zkkd5mMio5r4byKGPCLgW1EPW+tPzY1/QtgFoKsg8XI+9",

			"MIIC9DCCAdygAwIBAgIQFhHO15YMSWexXH6edHgfHjANBgkqhkiG9w0BAQsFADAg" +
			"MR4wHAYDVQQDDBVVbnRydXN0d29ydGh5IFJvb3QgQ0EwIBcNMTQwNzA0MDgyNzUy" +
			"WhgPMjExNDA3MTUwODI3NTJaMCgxJjAkBgNVBAMMHVVudHJ1c3R3b3J0aHkgSW50" +
			"ZXJtZWRpYXRlIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvVAo" +
			"TkWCq7GlDVLiuEFwEvJHcrwalv64XGWc42X/JUH8DEAf+1ZGOcemrbLDnqhO0dcF" +
			"FIlejjHNvjTHld1uJitBZKloi29sUUgQia8YPD+fY5UG/jgckzNv7JDeP+OGWmiD" +
			"p4xENpWfgvAZKWma0WHOe/Zx8Ye+uJLAv0Rq8lkszFvx+eEWhg6bi7OmPtBQrof+" +
			"5KeW9LlE3v6XM0ReOLKh3OPsiRabzqKSjqoqelouleEoMuCl0fZ2rK0gGsjjsQh+" +
			"0D+pe6GzuF+3oR31PELzO14a6MKkhrC+WdH8TdK8ndKnhfY8Najzf9wfYzeRkaJl" +
			"js+EUmT6MBKiQf1vewIDAQABoyAwHjALBgNVHQ8EBAMCAQYwDwYDVR0TAQH/BAUw" +
			"AwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAn+bt2+oNZVaG18H+NcSLmvZ1tVwtTk8M" +
			"yEZMaxqVCZsvkUucGgwssS1g7sEUg2CCH+oFdrrJyLC5fY/IO3aFYuHDjy8OqCr6" +
			"P/CR+2Dp+FBcQqiKSdTRxDPv9f7Yj9K3Ka2XfYsxVdIK+rr9HqCzETL7zMn+TVOj" +
			"mCcvIjP+N9oapFiX+Y0onTQuEQ/Xz7WmBpB1F3bK9oKc0XkxREggXzB2q1SHsgCh" +
			"tqU01V4wEjdRNHQrL/YsnsUTDJyw63QNCw9UEtIhE2NYWqTfPrjj+mcb/S1ew09Y" +
			"8VGZyWE1T3Ox/lsYvIpjOLpDoKzaq2TMzqwsyQJryYo0Nmp8GDAcaQ==",

			"MIIC7TCCAdWgAwIBAgIRAKHC3c5MpEKQiGjXsE5cB8AwDQYJKoZIhvcNAQELBQAw" +
			"IDEeMBwGA1UEAwwVVW50cnVzdHdvcnRoeSBSb290IENBMCAXDTE0MDcwNDA4Mjc1" +
			"MloYDzIxMTQwNzE1MDgyNzUyWjAgMR4wHAYDVQQDDBVVbnRydXN0d29ydGh5IFJv" +
			"b3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCwFNvOLX4xmqKo" +
			"sdZIn2EnWNrrMTwsF0XFaJgN1+4AmP8w6BpXq2IzZ3nEaB5bZ7DLrRhep06EzfGr" +
			"EaW7wUDFOHwN7HNiSVWtn6vZvAJF7vmvaYPewiHwOgeLXorWq00BikcbUn1OcgIQ" +
			"to2KAGvSljywyOuXMlgzOhfe35DPQ+IAyoqpsfR6rIrfhJiOSupmAJEXCxE/RoHl" +
			"JBPR81c4kqzKyG5dxMSXRwKIIncC200wr+EPGOPwgLhSR/587s24TFc5ihyWxQjg" +
			"szgmO0wr6AMqf57L63oaaLx2AK8ezJVO0qTsoQt/XPUSLdollNI0rDyQ55p4fe6Q" +
			"PxbGoq6PAgMBAAGjIDAeMAsGA1UdDwQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MA0G" +
			"CSqGSIb3DQEBCwUAA4IBAQCh9PtSDhqZ/M4chRaX/xLJnudsK2+wjNXJkt0OyLgp" +
			"OSLcOaiX9Bwx9IPbBYL6N3hSjXETMtgmYB73yD1a/nDwb4xckmPzM3S8sHE47Coa" +
			"oXL5NkJAHFAgu7Jh18Z2L2dweOD646daNpHmUYVBW4njtacQwghA71m5wNCefI0d" +
			"WOn9qAQ5b92493n2PYNocb0DzqpFE+PawIXscrY+kEiH2qhfRNXnYfxzuT5vn2z8" +
			"qA9NFh2SE7qfokR7/sop56VXg/f+gWRXYLZS2u3UrLtF3PC1dn97A2IMW4PJ3jxL" +
			"rA4yp0Yy5yPSLKxPsFig0PinI/7sURU9O1k91hWwmmDe"
		]
	end
	
	after(:each) do
		Dir["#{APP_ROOT}/spec/datasets/queue/*.json"].each { |f| File.unlink(f) }
	end

	context "a simple cert signed directly by a trusted root" do
		before :each do
			post '/add-chain', {'chain' => [inter]}.to_json
		end

		let!(:response) { last_response }

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
				der = inter.unbase64
				ct = [0, 0,                      # sct_version, signature_type
				      body['timestamp']/2**32,   # timestamp_hi
				      body['timestamp']%2**32,   # timestamp_lo
				      0,                         # entry_type
				      der.length/256,            # x509_entry_len_hi
				      der.length%256,            # x509_entry_len_lo
				      der,                       # cert
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
				expect(qents[0]['sct']).to eq(response.body)
			end

			it "has vaguely correct-looking leaf_input data" do
				expect(qents[0]['leaf_input']).to match(%r{^[A-Za-z+/=]+})
			end

			it "has the right chain" do
				expect(qents[0]['chain']).
				  to eq(["+NjzNHvI6diT5gF66jxKxPklpMEQFT9h93hlToajcno="])
			end
		end
	end

	context "chained cert" do
		let!(:response) do
			post '/add-chain', {'chain' => [cert, inter]}.to_json
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
				der = cert.unbase64
				ct = [0,0,                       # sct_version, signature_type
				      body['timestamp']/2**32,   # timestamp_hi
				      body['timestamp']%2**32,   # timestamp_lo
				      0,                         # entry_type
				      der.length/256,            # x509_entry_len_hi
				      der.length%256,            # x509_entry_len_lo
				      der,                       # cert
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
				  to eq(["oiZBE44OqR+ZxRMUhNKjIu68NHgpCtqKOGGbEeKpBRI=",
				         "+NjzNHvI6diT5gF66jxKxPklpMEQFT9h93hlToajcno="
				        ]
				       )
			end
		end
	end

	context "a certificate we've seen before" do
		let(:response) do
			post '/add-chain', {'chain' => [entry8, geotrust_inter]}.to_json
		end

		it "returns success" do
			expect(response.status).to eq(200)
		end

		it "returns JSON" do
			expect(response['Content-Type']).to eq("application/json; charset=UTF-8")
		end

		it "is the SCT stored in the sctdb" do
			expect(response.body).to eq("dummysct8")
		end
	end

	context "a certificate chained to a root we don't trust" do
		let(:response) do
			post '/add-chain', { 'chain' => untrusted_chain }.to_json
		end

		it "fails" do
			expect(response.status).to eq(400)
		end

		it "tells you why" do
			expect(response.body).to eq("Root certificate is not trusted")
		end
	end

	context "a body that isn't valid JSON" do
		let(:response) do
			post '/add-chain', "I AM A HAXXA!"
		end

		it "returns bad request" do
			expect(response.status).to eq(400)
		end

		it "returns plain text" do
			expect(response['Content-Type']).to eq("text/plain; charset=UTF-8")
		end

		it "tells us what went wroung" do
			expect(response.body).to eq("Failed to parse request body")
		end
	end
end
