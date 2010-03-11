# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_portland_session',
  :secret      => '688361affb6529b7f0d3c195ca1ff029d57642179dce123d30800dbb10841f6e46d34e8905880d4b6a7334f829aeeae8aea5d330566a9bedea016d4f1850d91f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
