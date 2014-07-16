module CertificateTransparency
	# Various enums and scrappy crap that isn't worth
	# a separate class for

	# RFC6962 s3.1
	LogEntryType = { :x509_entry => 0,
	                 :precert_entry => 1
	               }
	LogEntryType_len = 2

	# RFC6962 s3.4
	MerkleLeafType = { :timestamped_entry => 0
	                 }
	MerkleLeafType_len = 1

	# RFC6962 s3.2
	SignatureType = { :certificate_timestamp => 0,
	                  :tree_hash             => 1
	                }
	SignatureType_len = 1

	# RFC6962 s3.2
	Version = { :v1 => 0 }
	Version_len = 1
end

require_relative './certificate_transparency/certificate_timestamp'
require_relative './certificate_transparency/dai'
require_relative './certificate_transparency/hash_store'
require_relative './certificate_transparency/helpers'
require_relative './certificate_transparency/log_entry'
require_relative './certificate_transparency/merkle_tree_leaf'
require_relative './certificate_transparency/pre_cert'
require_relative './certificate_transparency/timestamped_entry'
require_relative './certificate_transparency/tree_head_signature'
