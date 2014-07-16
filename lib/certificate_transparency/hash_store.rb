require 'fileutils'

class CertificateTransparency::HashStore
	def initialize(basedir, hash, extension = nil)
		hexhash = hash.enhex
		basedir = File.expand_path(basedir)
		@path = "#{basedir}/#{hexhash[0..2]}/#{hexhash[3..5]}/#{hexhash}#{extension}"
	end

	def write(content)
		dir = File.dirname(@path)

		until File.exists?(dir)
			FileUtils.mkdir_p(dir)
		end

		File.write(@path, content)
	end

	def read
		File.read(@path)
	end

	def deref
		unless File.symlink?(@path)
			raise RuntimeError,
			      "Cannot dereference a regular file"
		end

		link = File.readlink(@path)

		File.expand_path(link, File.dirname(@path))
	end

	# Turn this HashStore entry into a symlink to another location, specified
	# by `f`.  Useful for making a tree that cross-references to other data
	def link(f)
		f = File.expand_path(f)

		File.unlink(@path)
		l = relative_path(File.dirname(@path), f)

		File.symlink(f, @path)
	end

	private
	# Given two absolute paths `from` (a directory) and `to` (any path),
	# determine the minimal relative path which would be needed to get from
	# `from` to `to`.  Useful for minimal relative symlinks.  Does not take
	# into account filesystem boundaries.
	#
	def relative_path(from, to)
		if from[0] != "/"
			raise ArgumentError,
			      "from is not an absolute path"
		end
		if to[0] != "/"
			raise ArgumentError,
			      "to is not an absolute path"
		end

		# Take off the trailing '/', if there is one -- that would make
		# a right mess of our algorithm
		if from[-1] == "/"
			from = from[0..-2]
		end

		from_parts = from[1..-1].split('/')
		to_parts = to[1..-1].split('/')


		# Start by trimming any common path components
		while from_parts[0] == to_parts[0]
			from_parts.shift
			to_parts.shift
		end

		(([".."] * from_parts.length) + to_parts).join('/')
	end
end
