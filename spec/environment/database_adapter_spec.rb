require "rails_helper"

RSpec.describe "Test environment configuration" do
  it "uses a SQLite database adapter in RAILS_ENV=test" do
    # The suite runs without a Postgres server. If the test adapter is switched
    # back to Postgres, this fails as a reminder to update the README setup.
    expect(ActiveRecord::Base.connection_db_config.adapter).to eq("sqlite3")
  end
end
