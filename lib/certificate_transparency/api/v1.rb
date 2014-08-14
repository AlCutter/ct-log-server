require 'certificate_transparency'
require 'merkle-hash-tree'
require 'digest/sha2'
require 'openssl'
require 'openssl_extension'
require 'string_extension'
require 'tls'
require 'rack/utils'

module CertificateTransparency::API; end

class CertificateTransparency::API::V1
	def initialize(opts)
		@options = opts
		@dai = @options[:dai]
		@mht = MerkleHashTree.new(@dai, Digest::SHA256)

		@logger = @options[:logger] or raise ArgumentError, "Need a :logger"


		if @options[:master_url]
			# We're a slave to our emotions
			@slave      = true
			@master_url = @options[:master_url]
		else
			# I am master of my domain!

			######################
			# :private_key_file
			unless @options.has_key?(:private_key_file)
				raise ArgumentError,
						"Mandatory argument :private_key_file not specified"
			end

			pkf = @options[:private_key_file]

			unless File.exists?(pkf)
				raise ArgumentError,
						"#{pkf}: Key file does not exist"
			end

			unless File.readable?(pkf)
				raise ArgumentError,
						"#{pkf}: Key file is not readable"
			end

			begin
				@key = OpenSSL::PKey::EC.new(File.read(pkf))
			rescue OpenSSL::PKey::ECError => e
				raise ArgumentError,
						"#{pkf}: Failed to read key file: #{e.message}"
			end

			pubkey = OpenSSL::PKey::EC.new('prime256v1')
			pubkey.public_key = @key.public_key
			@log_id = Digest::SHA256.digest(pubkey.to_der)

			######################
			# :queue_dir
			unless @options.has_key?(:queue_dir)
				raise ArgumentError,
				      "Master must have a queue to write new entries to"
			end

			qd = @options[:queue_dir]

			while File.symlink? qd
				qd = File.expand_path(File.readlink(qd), File.dirname(qd))
			end

			unless File.directory? qd
				raise ArgumentError,
				      "I must have a directory for my :queue_dir"
			end

			unless File.writable? qd
				raise ArgumentError,
				      "I must be able to write to my queue dir"
			end

			@queue_dir = qd
		end
	end

	ROUTES = [
	          ["POST", "/add-chain", :add_chain],
	          ["POST", "/add-pre-chain", :add_chain],
	          ["GET", "/get-sth", :get_sth],
	          ["GET", "/get-sth-consistency", :get_sth_consistency],
	          ["GET", "/get-proof-by-hash", :get_proof_by_hash],
	          ["GET", "/get-entries", :get_entries],
	          ["GET", "/get-roots", :get_roots],
	          ["GET", "/get-entry-and-proof", :get_entry_and_proof],
	         ]

	def call(env)
		@headers = []
		@status  = 555
		@env     = env
		content  = nil

		params = Rack::Utils.parse_query(env['QUERY_STRING'])

		routes = ROUTES.select { |c| c[1] == env["PATH_INFO"] }

		if routes.empty?
			content = error("Not found", 404)
		else
			route = routes.select { |c| c[0] == env["REQUEST_METHOD"] }

			content = if route.empty?
				error("Cannot use #{env["REQUEST_METHOD"]} on #{env["PATH_INFO"]}", 405)
			elsif route.length > 1
				raise RuntimeError,
						"Got multiple routes for #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"
			else
				__send__(route[0][2], params)
			end
		end

		[@status, @headers, [content]]
	end

	private
	def add_chain(params)
		if @slave
			uri = if @env["PATH_INFO"] == "/add-chain"
				URI.parse("#{@master_url}/ct/v1/add-chain")
			elsif @env["PATH_INFO"] == "/add-pre-chain"
				URI.parse("#{@master_url}/ct/v1/add-pre-chain")
			else
				raise RuntimeError,
				      "Unknown PATH_INFO: '#{@env["PATH_INFO"]}'"
			end

			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = uri.scheme == 'https'
			http.verify_mode = OpenSSL::SSL::VERIFY_PEER

			request = Net::HTTP::Post.new(uri.request_uri)
			request.body = @env['rack.input'].read
			request["Content-Type"] = "application/json; charset=UTF-8"

			response = http.request(request)

			status response.code.to_i
			set_header 'Content-Type', response['Content-Type']
			return response.body
		end

		########################
		# Param checks
		begin
			req_body = @env['rack.input'].read
			params = JSON.parse(req_body)
		rescue JSON::ParserError => e
			@logger.info "JSON parser failure in /add-chain: #{e.message}"
			@logger.info "-----8<-----"
			@logger.info req_body
			@logger.info "----->8-----"
			return error("Failed to parse request body")
		end

		unless params.has_key? 'chain'
			return error("Required key 'chain' missing")
		end

		#######################
		# Chain validation
		chain = valid_chain(params['chain'].map! { |c| OpenSSL::X509::Certificate.new(c.unbase64) })

		unless chain
			return error("Root certificate is not trusted")
		end

		eecert = chain[0]
		chain  = chain[1..-1]

		#######################
		# X509/precert decision
		entry_type = nil

		signed_entry = if @env["PATH_INFO"] == '/add-pre-chain'
			entry_type = :precert_entry
			tbscert = OpenSSL::ASN1.decode(eecert.to_der).value[0].to_der

			issuer_key_hash = Digest::SHA256.digest(chain[0].public_key.to_der)

			[issuer_key_hash, tbscert.length, tbscert].pack("a*na*")
		elsif @env["PATH_INFO"] == "/add-chain"
			entry_type = :x509_entry
			eecert.to_der
		else
			raise RuntimeError,
			      "Unknown PATH_INFO: '#{@env["PATH_INFO"]}'"
		end

		#######################
		# Catch repeat offenders
		if sct = @dai.sct(signed_entry)
			status 200
			json_response
			return sct
		end

		#######################
		# Construct the SCT

		ts = (Time.now.to_f*1000).to_i
		ct = ::CertificateTransparency::CertificateTimestamp.new(
		         :timestamp => ts,
		         entry_type => signed_entry
		       )

		ds = ::TLS::DigitallySigned.new(:key => @key, :content => ct.encode)

		sct = {:sct_version => 0,
		       :id          => @log_id.base64,
		       :timestamp   => ts,
		       :extensions  => "",
		       :signature   => ds.encode.base64
		      }.to_json

		tse = ::CertificateTransparency::TimestampedEntry.new(
					 :timestamp => ts,
					 entry_type => signed_entry
				  )
		mtl = ::CertificateTransparency::MerkleTreeLeaf.new(
					 :timestamped_entry => tse
				  )

		queue_entry = {
		  :sct        => sct,
		  :sct_hash   => Digest::SHA256.digest(signed_entry).base64,
		  :leaf_input => mtl.encode.base64,
		  :chain      => chain.map { |c| Digest::SHA256.digest(c.to_der).base64 }
		}.to_json

		begin
			qfile = "#{@queue_dir}/#{ts}_#{rand(1000000)}_#{$$}.json"
			File.open(qfile, File::WRONLY|File::CREAT|File::EXCL) do |fd|
				fd.write(queue_entry)
				fd.fsync
			end
		rescue Errno::EEXIST
			retry
		end

		status 200
		json_response
		sct
	end

	def get_sth(params)
		status 200
		json_response
		@dai.signed_tree_head
	end

	def get_sth_consistency(params)
		unless params.has_key? 'first'
			return error('first not specified')
		end
		unless params.has_key? 'second'
			return error('second not specified')
		end

		first = params['first'].to_i
		second = params['second'].to_i

		if second < first
			return error("first cannot be greater than second")
		end
		if second > @dai.length
			return error("second out of range")
		end
		if first < 0
			return error("first out of range")
		end

		proof = @mht.consistency_proof(first, second).map { |h| h.base64 }

		status 200
		json_response
		{ :consistency => proof }.to_json
	end

	def get_proof_by_hash(params)
		unless params.has_key? 'hash'
			return error('hash not specified')
		end
		unless params.has_key? 'tree_size'
			return error('tree_size not specified')
		end

		hash = params['hash'].unbase64
		size = params['tree_size'].to_i

		idx = @dai.id_from_hash(hash)
		if idx.nil?
			return error("Entry for hash not found", 404)
		end

		if size > @dai.length
			return error("tree_size out of range")
		end

		leaf = @dai[idx]

		extras = leaf.chain.map do |c|
			TLS::Opaque.new(2**24-1, :value => @dai.intermediate(c)).encode
		end
		extras = TLS::Opaque.new(2**24-1, :value => extras.join).encode

		status 200
		json_response
		{
		 :leaf_index => idx,
		 :audit_path => @mht.audit_proof(idx, 0..size-1).map { |h| h.base64 }
		}.to_json
	end

	def get_entries(params)
		unless params.has_key? 'start'
			return error('start not specified')
		end
		unless params.has_key? 'end'
			return error('end not specified')
		end

		first = params['start'].to_i
		last = params['end'].to_i

		if first > last
			return error("start cannot be greater than end")
		end
		if last >= @dai.length
			return error("end out of range")
		end
		if first < 0
			return error("start out of range")
		end

		# Limit response sizes, for sanity
		if last - first > 25
			last = first + 25
		end

		entries = (first..last).to_a.map do |i|
			leaf = @dai[i]

			extras = leaf.chain.map do |c|
				TLS::Opaque.new(2**24-1, :value => @dai.intermediate(c)).encode
			end
			extras = TLS::Opaque.new(2**24-1, :value => extras.join).encode

			{
			 :leaf_input => leaf.leaf_input.base64,
			 :extra_data => extras.base64
			}
		end

		status 200
		json_response
		{ :entries => entries }.to_json
	end

	def get_roots(params)
		status 200
		json_response
		"{\"certificates\":#{@dai.json_roots}}"
	end

	def get_entry_and_proof(params)
		unless params.has_key? 'leaf_index'
			return error('leaf_index not specified')
		end
		unless params.has_key? 'tree_size'
			return error('tree_size not specified')
		end

		idx = params['leaf_index'].to_i
		size = params['tree_size'].to_i
		if idx >= @dai.length
			return error("leaf_index out of range")
		end
		if size > @dai.length
			return error("tree_size out of range")
		end

		leaf = @dai[idx]

		extras = leaf.chain.map { |c| TLS::Opaque.new(2**24-1, :value => @dai.intermediate(c)).encode }
		extras = TLS::Opaque.new(2**24-1, :value => extras.join).encode

		status 200
		json_response
		{
		 :leaf_input => leaf.leaf_input.base64,
		 :extra_data => extras.base64,
		 :audit_path => @mht.audit_proof(idx, 0..size-1).map { |h| h.base64 }
		}.to_json
	end

	def set_header(h, v)
		@headers ||= []
		@headers.delete_if { |hdr| hdr[0] == h }
		add_header(h, v)
	end

	def add_header(h, v)
		@headers ||= []
		@headers << [h, v]
	end

	def status(n)
		@status = n.to_i
	end

	def error(str, sts=400)
		status sts
		set_header "Content-Type", "text/plain; charset=UTF-8"
		str
	end

	def json_response
		set_header "Content-Type", "application/json; charset=UTF-8"
	end

	# A validation to make any true PKIX lover cry... all we're doing
	# is checking signatures up to a cert in our root store.  No
	# expiry checking or anything else vaguely interesting going on.
	#
	# Pass in an array of OpenSSL::X509::Certificate objects, and we'll give
	# you back either the completed chain (with a root cert included), or
	# nil.  Every cert *except* the trusted root cert has to be in the chain
	# (we'll handle it whether or not the root cert is in there).
	def valid_chain(chain)
		chain[1..-1].each_with_index do |c, i|
			# Signature chain broke down... bugger that
			unless chain[i].verify(c.public_key)
				@logger.info "Chain validation failed:"
				@logger.info "-----8<-----"
				chain.each { |cert| @logger.info cert.to_s }
				@logger.info "----->8-----"
				@logger.info "Signature chain broken down between certs #{i} and #{i+1}"
				return nil
			end
		end

		# OpenSSL::X509::Certificate refuses to consider two certificates as
		# equal, even if they have the exact same content, so we need to
		# export the DER and check it ourselves
		if @dai.roots.map { |c| c.to_der }.include?(chain[-1].to_der)
			# The chain included a root, and it's one we like
			return chain
		end

		@dai.roots.each do |r|
			# Look for a root that signed the last cert in the chain
			begin
				chain[-1].verify(r.public_key) and return chain + [r]
			rescue StandardError
				next
			end
		end

		# None of those checks passed... FAIL
		@logger.info "Chain validation failed:"
		@logger.info "-----8<-----"
		chain.each { |cert| @logger.info cert.to_s }
		@logger.info "----->8-----"
		@logger.info "Root certificate was not in our trust store"

		return nil
	end
end
