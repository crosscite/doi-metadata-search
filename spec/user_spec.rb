require 'spec_helper'

describe User, vcr: true do
  let(:auth_hash) { OmniAuth.config.mock_auth[:jwt] }

  subject { User.new(auth_hash) }
end
