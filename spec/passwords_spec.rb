# frozen_string_literal: true

RSpec.describe LowAuth::Passwords do
  let(:users) { LowAuth.users }

  before do
    users.insert(username: 'LeadDog', email: 'lead@example.com', password_hash: described_class.digest('rye'))
  end

  it 'logs a user in by username or email, whatever the case' do
    expect(described_class.authenticate('leaddog', 'rye')[:username]).to eq('LeadDog')
    expect(described_class.authenticate('Lead@Example.com', 'rye')[:username]).to eq('LeadDog')
  end

  it "doesn't log a user in with the wrong password" do
    expect(described_class.authenticate('LeadDog', 'spelt')).to be_nil
  end

  it "doesn't log in someone who isn't a user" do
    expect(described_class.authenticate('nobody', 'rye')).to be_nil
  end

  it "doesn't log in a user who can't log in" do
    users.where(username: 'LeadDog').update(blocked: true)

    expect(described_class.authenticate('LeadDog', 'rye')).to be_nil
  end

  context 'with only an old hash' do
    before { users.insert(username: 'celia', old_hash: 'old:wheat') }

    it 'logs the user in and rehashes their password with Argon2' do
      expect(described_class.authenticate('celia', 'wheat')[:username]).to eq('celia')
      expect(users.where(username: 'celia').get(:password_hash)).to start_with('$argon2id$')
    end

    it "doesn't rehash the wrong password" do
      expect(described_class.authenticate('celia', 'rye')).to be_nil
      expect(users.where(username: 'celia').get(:password_hash)).to be_nil
    end
  end

  it "doesn't check the old hash once the password has been rehashed" do
    users.insert(username: 'skua', old_hash: 'old:spelt', password_hash: described_class.digest('rye'))

    expect(described_class.authenticate('skua', 'spelt')).to be_nil
  end
end
