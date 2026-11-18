# frozen_string_literal: true

RSpec.describe 'LowAuth.same_origin?' do
  def same_origin?(headers)
    LowAuth.same_origin?(LowAuthSpec::Event.from(headers:))
  end

  it 'matches an origin on the usual port' do
    expect(same_origin?('origin' => 'https://example.com')).to be(true)
  end

  it 'matches an origin with a port' do
    expect(same_origin?('host' => '127.0.0.1:4133', 'origin' => 'http://127.0.0.1:4133')).to be(true)
  end

  it 'matches a referer without an origin' do
    expect(same_origin?('referer' => 'https://example.com/login')).to be(true)
  end

  it "doesn't match another site" do
    expect(same_origin?('origin' => 'https://example.com.evil.example')).to be(false)
  end
end
