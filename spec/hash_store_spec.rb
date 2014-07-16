require_relative './spec_helper'
require 'certificate_transparency'

describe "CertificateTransparency::HashStore" do
	context "#relative_path" do
		let(:hs) { CertificateTransparency::HashStore.new("", "") }

		it "works in the same directory" do
			expect(hs.send(:relative_path, "/foo/bar", "/foo/bar/baz")).
			  to eq("baz")
		end

		it "works from subdirectories" do
			expect(hs.send(:relative_path, "/foo/bar/wombat", "/foo/bar/baz")).
			  to eq("../baz")
		end

		it "works in different hierarchies" do
			expect(hs.send(:relative_path, "/foo/xyzzy/bar/wombat", "/foo/bar/baz")).
			  to eq("../../../bar/baz")
		end

		it "works with trailing slashes" do
			expect(hs.send(:relative_path, "/foo/xyzzy/bar/wombat/", "/foo/bar/baz")).
			  to eq("../../../bar/baz")
		end
	end
end
