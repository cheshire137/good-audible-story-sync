require_relative "lib/good_audible_story_sync"

db_client = nil
def load_db_client
  db_client ||= GoodAudibleStorySync::Database::Client.load
end

options = nil
def load_options
  options ||= GoodAudibleStorySync::Options.default
end

def get_audible_auth(db_client=nil)
  GoodAudibleStorySync::Audible::AuthFlow.run(db_client: db_client || load_db_client)
end

def get_audible_client(db_client: nil, auth: nil, options: nil)
  auth ||= get_audible_auth(db_client)
  options ||= load_options
  GoodAudibleStorySync::Audible::Client.new(auth: auth, options: options,
    credentials_db: (db_client || load_db_client).credentials)
end

def get_storygraph_auth(db_client=nil)
  GoodAudibleStorySync::Storygraph::AuthFlow.run(credentials_db: (db_client || load_db_client).credentials)
end

def get_storygraph_client(db_client: nil, auth: nil)
  auth ||= get_storygraph_auth(db_client)
  GoodAudibleStorySync::Storygraph::Client.new(auth: auth)
end

def get_goodreads_auth(db_client=nil)
  GoodAudibleStorySync::Goodreads::AuthFlow.run(credentials_db: (db_client || load_db_client).credentials)
end

def get_goodreads_client(db_client: nil, auth: nil)
  auth ||= get_goodreads_auth(db_client)
  GoodAudibleStorySync::Goodreads::Client.new(auth: auth)
end
