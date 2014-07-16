require 'json'
require 'gdbm'
require 'openssl'

module CertificateTransparency; end

class CertificateTransparency::DAI
	class DatabaseExpired < StandardError; end

	def initialize(dbfile, cache)
		unless File.exists?(dbfile)
			raise ArgumentError,
			      "Data file #{dbfile} does not exist"
		end

		unless File.readable?(dbfile)
			raise ArgumentError,
			      "Data file #{dbfile} is not readable"
		end

		@dbfile = dbfile
		@cache  = cache
	end

	############################
	# Standard MHT DAI
	def length
		raise DatabaseExpired if expired?

		rolled_over? ? @cur_length : @prev_length
	end

	def [](n)
		raise DatabaseExpired if expired?

		# 'l' is for "Log Entry", it's good enough for me
		key = "le-#{n}"

		in_db do |db|
			::CertificateTransparency::LogEntry.new(db[key])
		end
	end

	def mht_cache_get(k)
		@cache and (x = @cache.get(k)) ? x.force_encoding("BINARY") : nil
	end

	def mht_cache_set(k, v)
		@cache and @cache.set(k, v)
	end

	############################
	# Extensions

	# Look up an intermediate certificate from its hash (specified as a raw
	# octet string), and return the certificate data as a DER-encoded string
	def intermediate(hash)
		raise DatabaseExpired if expired?

		# 'i' is for "Intermediate certificate"
		key = "i-#{hash}"
		in_db do |db|
			db[key]
		end
	end

	# Given the hash of a MerkleHashTree (as a string as raw octets), find
	# the ID of the entry that corresponds.
	def id_from_hash(hash)
		raise DatabaseExpired if expired?

		key = "lh-#{hash}"
		id = in_db { |db| db[key] }
		if id
			id = id.to_i
		end
		id
	end
	
	# Retrieve the SCT for a specified "signed entry", if one exists,
	# or return nil
	def sct(signed_entry)
		in_db { |db| db["sct-"+Digest::SHA256.digest(signed_entry)] }
	end

	# Get all our root certificates as an array of OpenSSL::X509::Certificates
	def roots
		@roots ||= begin
			JSON.parse(json_roots).map do |c|
				OpenSSL::X509::Certificate.new(c.unbase64)
			end
		end
	end

	def json_roots
		raise DatabaseExpired if expired?

		@json_roots ||= begin
			in_db { |db| db["roots"] }
		end
	end

	def signed_tree_head
		raise DatabaseExpired if expired?

		rolled_over? ? @cur_sth : @prev_sth
	end

	private
	def update_vars
		if @mtime != File.stat(@dbfile).mtime
			# New database has arrived... time to update our cache of the important
			# values
			in_db do |db|
				@cur_sth       = db["cur_sth"]
				@prev_sth      = db["prev_sth"]
				@cur_length    = db["cur_tree_size"].to_i
				@prev_length   = db["prev_tree_size"].to_i
				@expiry_time   = db["expiry_time"].to_i
				@rollover_time = db["rollover_time"].to_i
				
				# Clear caches
				@roots = nil
				@json_roots = nil
			end
		end
	end

	def rolled_over?
		@rollover_time < Time.now.to_i
	end

	def expired?
		update_vars

		Time.now.to_i > @expiry_time
	end
	
	def in_db
		unless block_given?
			raise ArgumentError,
			      "Must pass a block to #in_db"
		end
		
		begin
			GDBM.open(@dbfile, 0600, GDBM::READER) { |db| yield db }
		rescue Errno::EAGAIN
			retry
		end
	end
end
