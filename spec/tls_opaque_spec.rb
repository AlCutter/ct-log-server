require_relative './spec_helper'
require_relative '../lib/tls'

describe "TLS::Opaque" do
	it "accepts :value" do
		expect { TLS::Opaque.new(5, :value => "\0") }.to_not raise_error
	end

	it "accepts :blob" do
		expect { TLS::Opaque.new(5, :blob => "\0") }.to_not raise_error
	end

	it "doesn't accept both :value and :blob" do
		expect { TLS::Opaque.new(5, :value => "x", :blob => "x") }.
		  to raise_error(ArgumentError, /both :value and :blob/)
	end

	it "fails without the max length" do
		expect { TLS::Opaque.new(:value => "x") }.
		  to raise_error(ArgumentError, /wrong number of arguments \(1 for 2\)/)
	end

	it "fails if the max length is something craycray" do
		expect { TLS::Opaque.new("craycray", :value => "x") }.
		  to raise_error(ArgumentError, /Integer/)
	end

	it "fails when neither of :value or :blob are given" do
		expect { TLS::Opaque.new(12, :something => "x") }.
		  to raise_error(ArgumentError, /exactly one of :value or :blob/)
	end

	it "fails when given a :value that is too long" do
		expect { TLS::Opaque.new(5, :value => "abcdef") }.
		  to raise_error(ArgumentError, /5/)
	end

	it "fails when given a :blob that is too long" do
		expect { TLS::Opaque.new(5, :blob => "\x06abcdef") }.
		  to raise_error(ArgumentError, /too long/)
	end

	it "doesn't fail when given a :blob that is exactly the right length" do
		expect { TLS::Opaque.new(5, :blob => "\x05abcde") }.
		  to_not raise_error
	end

	it "fails when :blob is incorrectly encoded" do
		expect { TLS::Opaque.new(255, :blob => "\x03ohai") }.
		  to raise_error(ArgumentError, /corrupt/)
	end

	# If you're encoding a string that could potentially be greater
	# than 18 exabytes long, I want your computer!
	[1, 2, 3, 4, 5, 6, 7, 8].each do |lenlen|
		it "encodes a #{lenlen}-byte-length string" do
			expect(TLS::Opaque.new(2**(lenlen*8)-1, :value => "ohai").encode).
			  to eq("\0"*(lenlen-1)+"\x04ohai")
		end

		it "decodes a #{lenlen}-byte-length string" do
			blob = "\0"*(lenlen-1) + "\x04ohai"

			expect(TLS::Opaque.new(2**(lenlen*8)-1, :blob => blob).value).
			  to eq("ohai")
		end
	end
end
