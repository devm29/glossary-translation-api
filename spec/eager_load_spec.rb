require "rails_helper"

# The test environment loads constants lazily, production eagerly. Loading
# everything here makes a file whose constant does not match its path fail the
# suite rather than the first production boot.
RSpec.describe "Eager loading" do
  it "loads every autoloaded constant" do
    expect { Rails.application.eager_load! }.not_to raise_error
  end
end
