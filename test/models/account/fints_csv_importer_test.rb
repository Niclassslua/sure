require "test_helper"

class FintsCsvImporterTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:depository)
  end

  test "imports new transactions and ignores duplicates" do
    csv = <<~CSV
      date*,amount*,name,currency,category,tags,account,notes
      01/02/2024,-10.00,Test,USD,,,
    CSV

    importer = Account::FintsCsvImporter.new(@account, csv)

    assert_difference -> { @account.entries.count }, +1 do
      added = importer.import!
      assert_equal 1, added
    end

    importer = Account::FintsCsvImporter.new(@account, csv)
    assert_no_difference -> { @account.entries.count } do
      added = importer.import!
      assert_equal 0, added
    end
  end
end
